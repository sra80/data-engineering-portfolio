create or alter procedure [marketing].[CSH_Moving_Extended_Reload]

as

set nocount on

update db_sys.process_model set disable_process = 1 where model_name = 'Marketing_CRM'

declare @csh table (cus nvarchar(20), date_start date)

declare @rc int = 1

while @rc > 0

begin

delete from @csh

insert into @csh (cus, date_start)
select top 3000 No_, [Start Date] from ext.Customer_Status_History where Merged_CSH_Moving_Extended_TSUTC is null

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
                select
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
            join
                @csh csh
            on
                (
                    Customer_Status_History.No_ = csh.cus
                and Customer_Status_History.[Start Date] = csh.date_start
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
            sales.first_order_cus,
            sales.first_order_range,
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
                    (select min(order_range_start) from (values(af.active_from)/**/,(h.[Status Start Date]),(h.[Last Order]),(convert(date,dateadd(year,-1,getutcdate())))) as value(order_range_start)) order_range_start, 
                    h.Ecosystem,
                    h.[Opt In], 
                    h.[Status Start Date],
                    h.[Status End Date],
                    marketing.fn_csh_opt_source_lookup(opt_source) opt_source_key,
                    h.eco_state_change,
                    h.opt_state_change
                from 
                    [stg].[CSH_Moving_Extended] h
                outer apply
                    marketing.fn_CSH_Moving_Active_Start (h.No_) af --
                where
                    (
                        [Status] < 4
                    --and h.[End Date] is not null
                    )
            ) cus_status
        outer apply
            marketing.fn_SalesOrders(cus_status.No_,cus_status.order_range_start,cus_status.[Status End Date]) sales
        
        update ext.Customer_Status_History set Merged_CSH_Moving_Extended_TSUTC = getutcdate() where exists (select 1 from @csh csh where Customer_Status_History.No_ = csh.cus and Customer_Status_History.[Start Date] = csh.date_start)

end

update db_sys.process_model set disable_process = 0 where model_name = 'Marketing_CRM'

-- update db_sys.process_model_partitions set process = 1 where model_name = 'Marketing_CRM'
GO
