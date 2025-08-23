CREATE procedure [marketing].[CSH_Moving_Extended_SKU_reload]

as

set nocount on

update db_sys.process_model set disable_process = 1 where model_name = 'Marketing_CRM'

drop table if exists tmp.CSH_Moving_Extended_SKU_reload

create table tmp.CSH_Moving_Extended_SKU_reload ([No_] nvarchar(20), [Start Date] date constraint PK__CSH_Moving_Extended_SKU_reload primary key ([No_],[Start Date]))

truncate table marketing.CSH_Moving_Extended_SKU

declare @t table (No_ nvarchar(20), [Start Date] date, [End Date] date, [Status] int, [Last Order] date, Ecosystem int, [Opt In] bit, [Status Start Date] date, [Status End Date] date, opt_source_key int, eco_state_change bit, opt_state_change bit)

declare @rowcount int = 1

while @rowcount > 0

begin

    delete from @t

    insert into @t 
        (
            No_, 
            [Start Date], 
            [End Date], 
            [Status], 
            [Last Order], 
            Ecosystem,
            [Opt In], 
            [Status Start Date],
            [Status End Date],
            opt_source_key,
            eco_state_change,
            opt_state_change
        )
        select top 10000
            h.No_, 
            h.[Start Date], 
            h.[End Date], 
            h.[Status], 
            h.[Last Order], 
            h.Ecosystem,
            h.[Opt In], 
            h.[Status Start Date],
            h.[Status End Date],
            h.opt_source_key,
            h.eco_state_change,
            h.opt_state_change
        from
            [marketing].[CSH_Moving_Extended] h
        left join
            tmp.CSH_Moving_Extended_SKU_reload r
        on
            (
                h.[No_] = r.[No_]
            and h.[Start Date] = r.[Start Date]
            )
        where
            (
                [Status] < 4
            and r.[No_] is null
            and r.[Start Date] is null
            )

    select @rowcount = isnull(sum(1),0) from @t

    insert into tmp.CSH_Moving_Extended_SKU_reload (No_, [Start Date]) select No_, [Start Date] from @t

    insert into marketing.CSH_Moving_Extended_SKU (cus, _start_date, _end_date, _start_date_status, _end_date_status, _status, channel_code, sku, order_date, first_order_cus, first_order_range, opt_in_email, ecosystem, opt_source_key, eco_state_change, opt_state_change, first_order_sku)
    select 
        cus_status.No_ cus,
        cus_status.[Start Date] _start_date,
        cus_status._end_date,
        cus_status.[Status Start Date] _start_date_status,
        cus_status.[Status End Date] _end_date_status,
        cus_status.[Status] _status,
        isnull(sales.channel_code,'unknown') channel_code,
        isnull(sales.sku,'out_of_range') sku,
        isnull(sales.order_date,cus_status.[Start Date]) order_date,
        (select min(first_order) from ext.Customer_Item_Summary cis where cis.cus = cus_status.No_) first_order_cus,
        (
            select 
                min(cis1.first_order)
            from
                ext.Customer_Item_Summary cis0
            join
                dbo.Item i0
            on
                (
                    cis0.sku = i0.No_
                )
            join
                dbo.Item i1
            on
                i0.[Range Code] = i1.[Range Code]
            join
                ext.Customer_Item_Summary cis1
            on
                (
                    cis0.cus = cis1.cus
                and i1.No_ = cis1.sku
                )
            where
                (
                    cis0.cus = cus_status.No_
                and cis0.sku = sales.sku
                )
        ) first_order_range,
        cus_status.[Opt In] opt_in_email,
        cus_status.Ecosystem,
        cus_status.opt_source_key,
        cus_status.eco_state_change,
        cus_status.opt_state_change,
        (select first_order from ext.Customer_Item_Summary cis where cus_status.No_ = cis.cus and sales.sku = cis.sku)
    from
        (
            select
                h.No_, 
                h.[Start Date], 
                h.[End Date] _end_date, 
                h.[Status], 
                h.[Last Order], 
                h.Ecosystem,
                h.[Opt In], 
                h.[Status Start Date],
                h.[Status End Date],
                h.opt_source_key,
                h.eco_state_change,
                h.opt_state_change
            from 
                @t h
        ) cus_status
        outer apply
                (
                    select
                        sku,
                        channel_code,
                        max(order_date) order_date
                    from
                        (
                            select
                                x.order_date,
                                x.sku,
                                x.channel_code 
                            from
                                (
                                select 
                                        convert(date,h.[Order Date]) order_date,
                                        h.[Sell-to Customer No_] cus,
                                        coalesce(nullif(h.[Channel Code],''),'PHONE') channel_code,
                                        l.No_ sku
                                    from
                                        ext.Sales_Header h
                                    join
                                        ext.Sales_Line l
                                    on
                                        (
                                            h.No_ = l.[Document No_]
                                        and h.[Document Type] = l.[Document Type]
                                        )
                                    where
                                        (
                                            h.[Sales Order Status] = 1
                                        and h.[Sell-to Customer No_] = cus_status.No_
                                        and h.[Order Date] >= dateadd(year,-1,cus_status.[Status Start Date])
                                        and h.[Order Date] <= isnull(cus_status.[Status End Date],convert(date,getutcdate()))
                                        )

                                    union all

                                    select
                                        convert(date,h.[Order Date]) order_date,
                                        h.[Sell-to Customer No_] cus,
                                        coalesce(nullif(h.[Channel Code],''),'PHONE') channel_code,
                                        l.No_ sku
                                    from
                                        ext.Sales_Header_Archive h
                                    join
                                        ext.Sales_Line_Archive l
                                    on
                                        (
                                            h.No_ = l.[Document No_]
                                        and h.[Document Type] = l.[Document Type]
                                        and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
                                        and h.[Version No_] = l.[Version No_]
                                        )
                                    where
                                        (
                                            h.[Sell-to Customer No_] = cus_status.No_
                                        and h.[Order Date] >= dateadd(year,-1,cus_status.[Status Start Date])
                                        and h.[Order Date] <= isnull(cus_status.[Status End Date],convert(date,getutcdate()))
                                        )
                                    ) x
                                where
                                    (   
                                        len(x.sku) > 0
                                    )
                        ) agg
                    group by
                        sku,
                        channel_code
                ) sales

    set @rowcount = @@rowcount

end

-- update db_sys.process_model_partitions set process = 1 where model_name = 'Marketing_CRM'

update db_sys.process_model set disable_process = 0 where model_name = 'Marketing_CRM'
GO
