create or alter procedure stock.sp_item_packaging_transactions_rebuild
    (
        @eom_period date,
        @is_test bit = 0
    )

as

set nocount on

declare @fom_period date
    
set @eom_period = eomonth(@eom_period)

delete from stock.item_packaging_transactions where key_posting_date = @eom_period

set @fom_period = eomonth(@eom_period,-1)

if @is_test = 0

    begin /*a139*/

        insert into stock.item_packaging_transactions (key_posting_date, key_location, is_ic, is_int, key_batch, quantity)
        select
            @eom_period key_posting_date,
            l.ID key_location,
            ile.is_ic, --intercompany
            ile.is_int,
            ile.key_batch,
            sum(-ile.Quantity) Quantity
        from
            (
                select
                    e.[Location Code],
                    case when c.[Customer Type] = 'IC' then 1 else 0 end is_ic, --intercompany
                    case when isnull(nullif(ssh.[Ship-to Country_Region Code],''),'GB') = 'GB' then 1 else 0 end is_int, --international
                    ext.fn_Item_Batch_Info(1, e.[Item No_], e.[Variant Code], e.[Lot No_]) key_batch,
                    Quantity
                from
                    [dbo].[UK$Item Ledger Entry] e
                left join
                    [dbo].[UK$Customer] c
                on
                    (
                        e.[Source No_] = c.No_
                    )
                left join
                    [dbo].[UK$Sales Shipment Header] ssh
                on
                    (
                        e.[Document No_] = ssh.[No_]
                    )
                where
                    (
                        e.[Document Type] = 1
                    and e.[Posting Date] > @fom_period
                    and e.[Posting Date] < dateadd(day,1,@eom_period)
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
            l.ID,
            ile.is_ic,
            ile.is_int,
            ile.key_batch

    end /*a139*/

if @is_test = 1

    begin /*1a12*/

        select
            @eom_period key_posting_date,
            l.ID key_location,
            ile.is_ic, --intercompany
            ile.is_int, --international
            ile.key_batch,
            sum(-ile.Quantity) Quantity
        from
            (
                select
                    e.[Location Code],
                    case when c.[Customer Type] = 'IC' then 1 else 0 end is_ic, --intercompany
                    case when isnull(nullif(ssh.[Ship-to Country_Region Code],''),'GB') = 'GB' then 0 else 1 end is_int,
                    ext.fn_Item_Batch_Info(1, e.[Item No_], e.[Variant Code], e.[Lot No_]) key_batch,
                    Quantity
                from
                    [dbo].[UK$Item Ledger Entry] e
                left join
                    [dbo].[UK$Customer] c
                on
                    (
                        e.[Source No_] = c.No_
                    )
                left join
                    [dbo].[UK$Sales Shipment Header] ssh
                on
                    (
                        e.[Document No_] = ssh.[No_]
                    )
                where
                    (
                        e.[Document Type] = 1
                    and e.[Posting Date] > @fom_period
                    and e.[Posting Date] < dateadd(day,1,@eom_period)
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
            l.ID,
            ile.is_ic,
            ile.is_int,
            ile.key_batch

    end /*1a12*/