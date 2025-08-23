CREATE procedure [marketing].[sp_CSH_Moving_Extended_initial]

as

set nocount on

-- update ext.Customer_Status_History set Merged_CSH_Moving_Extended_TSUTC = null

-- truncate table marketing.CSH_Moving_Extended

-- truncate table marketing.CSH_Moving_Extended_SKU 

update db_sys.process_model set disable_process = 1 where model_name = 'Marketing_CRM'

declare @rc int = 1

while @rc > 0

    begin

        truncate table [stg].[CSH_Moving_Extended]

        insert into [stg].[CSH_Moving_Extended] ([No_], [Start Date], [End Date], [Status], [Last Order], [Opt In], [Ecosystem], [Status Start Date], [Status End Date], opt_source, eco_state_change, opt_state_change)
        select 
            h.No_,
            e._start_date,
            e._end_date,
            h.[Status],
            h.[Last Order],
            e.opt_in_status,
            e.ecosystem,
            h.[Start Date],
            h.[End Date],
            e.opt_source,
            e.eco_state_change,
            e.opt_state_change
        from
            (
                select top 2000 
                    No_, 
                    [Status], 
                    [Last Order], 
                    [Start Date], 
                    [End Date], 
                    Merged_CSH_Moving_Extended_TSUTC, 
                    AddedTSUTC, 
                    UpdatedTSUTC 
            from 
                ext.Customer_Status_History
            where
                (
                    Merged_CSH_Moving_Extended_TSUTC is null
                )
            ) h
        outer apply
            marketing.fn_CSH_Moving_Extended(h.No_, h.[Start Date],h.[End Date]) e

        set @rc = @@rowcount

        insert into marketing.csh_opt_source (opt_source, opt_source_clean)
        select distinct opt_source, opt_source from [stg].[CSH_Moving_Extended] where len(opt_source) > 0 and opt_source not in (select opt_source from marketing.csh_opt_source)
        
        insert into [marketing].[CSH_Moving_Extended] ([No_], [Start Date], [End Date], [Status], [Last Order], [Opt In], [Ecosystem], [Status Start Date], [Status End Date],opt_source_key,eco_state_change,opt_state_change)
        select [No_], [Start Date], [End Date], [Status], [Last Order], [Opt In], [Ecosystem], [Status Start Date], [Status End Date], marketing.fn_csh_opt_source_lookup(opt_source), eco_state_change, opt_state_change  from [stg].[CSH_Moving_Extended]

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
                    marketing.fn_csh_opt_source_lookup(opt_source) opt_source_key,
                    h.eco_state_change,
                    h.opt_state_change
                from 
                    [stg].[CSH_Moving_Extended] h
                where
                    (
                        [Status] < 4
                    )
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
        
        update ext.Customer_Status_History set Merged_CSH_Moving_Extended_TSUTC = getutcdate() where exists (select distinct No_,[Status Start Date] from [stg].[CSH_Moving_Extended] s where Customer_Status_History.No_ = s.No_ and Customer_Status_History.[Start Date] = s.[Status Start Date])

    end

    update db_sys.process_model set disable_process = 0 where model_name = 'Marketing_CRM'

    -- update db_sys.process_model_partitions set process = 1 where model_name = 'Marketing_CRM'
GO
