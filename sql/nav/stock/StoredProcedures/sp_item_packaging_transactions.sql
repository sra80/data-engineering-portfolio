create or alter procedure stock.sp_item_packaging_transactions
    (
        @rebuild_from date = null
    )

as

set nocount on

if datediff(day,(select last_processed from db_sys.procedure_schedule where procedureName = 'stock.sp_item_packaging_transactions'),getutcdate()) > 0 or @rebuild_from between eomonth(datefromparts(year(getutcdate())-3,12,1)) and eomonth(getutcdate())

    begin /*88ca*/

        declare @fom_period date, @eom_period date

        if @rebuild_from is null

            select
                @eom_period = eomonth(max(key_posting_date))
            from
                stock.item_packaging_transactions

        else

            set @eom_period = eomonth(@rebuild_from)

        if @eom_period is null set @eom_period = eomonth(datefromparts(year(getutcdate())-2,1,1))

        if @eom_period > eomonth(getutcdate(),-2) set @eom_period = eomonth(getutcdate(),-2)

        delete from stock.item_packaging_transactions where key_posting_date >= @eom_period

        set @fom_period = dateadd(day,1,eomonth(@eom_period,-1))

        while @eom_period <= eomonth(getutcdate())

            begin /*a139*/

                insert into stock.item_packaging_transactions (country_id, key_posting_date, key_location, is_ic, is_int, is_amazon, key_batch, quantity)
                select
                    ile.country_id,
                    @eom_period key_posting_date,
                    l.ID key_location,
                    ile.is_ic,
                    ile.is_int,
                    ile.is_amazon,
                    ile.key_batch,
                    sum(-ile.Quantity)
                from
                    (
                        select
                            k.country_id,
                            e.[Location Code],
                            case when c.[Customer Type] = 'IC' then 1 else 0 end is_ic, --intercompany
                            case when cr.country_code in ('EN','XI','CT','WA') then 0 else 1 end is_int, --international
                            case when e.[Location Code] = amz.warehouse then 1 else 0 end is_amazon,
                            ext.fn_Item_Batch_Info(1, e.[Item No_], e.[Variant Code], e.[Lot No_]) key_batch,
                            Quantity
                        from
                            [dbo].[UK$Item Ledger Entry] e
                        join
                            ext.Item_Ledger_Entry k
                        on
                            (
                                e.[Entry No_] = k.ile_entry_no
                            and k.company_id = 1
                            )
                        join
                            ext.Country_Region cr
                        on
                            (
                                k.country_id = cr.ID
                            )
                        left join
                            [dbo].[UK$Customer] c
                        on
                            (
                                e.[Source No_] = c.No_
                            )
                        left join
                            finance.SalesInvoices_Amazon amz
                        on
                            (
                                e.[Location Code] = amz.warehouse
                            )
                        where
                            (
                                (
                                    e.[Document Type] = 1
                                or
                                    (
                                        e.[Document Type] = 0
                                    and e.[Location Code] = amz.warehouse
                                    )
                                )
                            and convert(date,e.[Posting Date]) between @fom_period and @eom_period
                            )
                        ) ile
                join
                    ext.Location l
                on
                    (
                        l.company_id = 1
                    and ile.[Location Code] = l.location_code
                    )
                group by
                    ile.country_id,
                    l.ID,
                    ile.is_ic,
                    ile.is_int,
                    ile.is_amazon,
                    ile.key_batch

                set @fom_period = dateadd(day,1,@eom_period)
                
                set @eom_period = eomonth(@eom_period,1)

            end /*a139*/

    end /*88ca*/