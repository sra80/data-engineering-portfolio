create or alter view [marketing].[CSH_Moving_Window]

as

-- added convert(date,dateadd(year,-1,getutcdate())))) to value(order_range_start) in cus_status cte, covers goods purchased within previous year
-- added first_order_cus & first_order_range
-- added ecosystems
-- added partitions, refer to fixed column [End Date] in marketing.Customer_Status_History_prefEmail instead of using window function
-- marketing.CSH_Moving_Extended_SKU now holding all active and marketing.CSH_Moving_Extended all, i.e. only these are required sourced
-- add r.risk_factor and r.risk_days_left
-- add prospect data
-- add opt_source_key (source of opt in/out), eco_state_change, opt_state_change
-- add opt_source_key to prospect data
-- for opt_state_change set to 0 if initial opt-in state is [out], required for calculating churn rate
-- add prediction on customers going into a lapsed state
-- add and csh.[Last Order] > convert(date,getutcdate()) for  exclude records timing out today
-- fixes to csh_end where commented
-- only anticipate lapse from tomorrow
-- add first_order_sku
-- include today for estimated lapsed customers for future or forecast lapsed customers
-- ref , include prediction within ranges
-- change to , order_date should be last order date by customer as this determines if customer will lapse, not determined at sku level

select
    e._start_date csh_start,
    isnull(e._end_date,dateadd(year,1,dateadd(day,-1,e.order_date))) csh_end,
    e.order_date,
    e._status csh_status,
    e.cus,
    e.channel_code,
    e.sku,
    e.opt_in_email opt_status,
    e._start_date_status csh_status_start,
    e.first_order_cus,
    e.first_order_range,
    e.first_order_sku,
    e.ecosystem,
    p._partition,
    r.risk_factor,
    r.risk_days_left,
    e.opt_source_key,
    e.eco_state_change,
    marketing.fn_opt_in_email_change(e.cus, e._start_date, e.opt_in_email, e.opt_state_change) opt_state_change
from
    marketing.CSH_Moving_Extended_SKU e
cross apply
    [db_sys].[model_partition_bi] p
cross apply
    marketing.fn_CSH_Moving_Risk(e.cus,e._start_date_status) r
where
    (
        isnull(e._end_date,convert(date,getutcdate())) >= p.date_start
    and isnull(e._end_date,convert(date,getutcdate())) <= p.date_end
    )
/* start***/

union all

select
    dateadd(year,1,e.order_date) csh_start,
    dateadd(year,2,dateadd(day,-1,e.order_date)) csh_end,
    e.order_date,
    7 csh_status,
    e.cus,
    e.channel_code,
    e.sku,
    e.opt_in_email opt_status,
    dateadd(year,1,e._start_date_status) csh_status_start,
    e.first_order_cus,
    e.first_order_range,
    e.first_order_sku,
    e.ecosystem,
    90 _partition,
    1 risk_factor,
    0 risk_days_left,
    -1 opt_source_key,
    convert(bit,0) eco_state_change,
    convert(bit,0) opt_state_change
from
    (
        select
            cus,
            channel_code,
            sku,
            opt_in_email,
            max(order_date) over (partition by cus) _start_date_status,
            max(order_date) over (partition by cus) order_date,
            first_order_cus,
            first_order_range,
            first_order_sku,
            ecosystem,
            _status
        from
            marketing.CSH_Moving_Extended_SKU
        where
            (
                _end_date is null
            )
        ) e
join
    ext.Customer_Status s
on
    (
        e._status = s.ID
    )
where
    (
        s.is_customer = 1
    and s.is_active = 1
    and e.order_date < convert(date,getutcdate()) --
    and e.order_date >= convert(date,dateadd(year,-1,getutcdate())) --
    )
/* end***/

/* start***/
/*
union all

select
    dateadd(year,1,e.order_date) csh_start,
    dateadd(year,2,dateadd(day,-1,e.order_date)) csh_end,
    e.order_date,
    7 csh_status,
    e.cus,
    e.channel_code,
    e.sku,
    e.opt_in_email opt_status,
    dateadd(year,1,e._start_date_status) csh_status_start,
    e.first_order_cus,
    e.first_order_range,
    e.first_order_sku,
    e.ecosystem,
    90 _partition,
    1 risk_factor,
    0 risk_days_left,
    -1 opt_source_key,
    convert(bit,0) eco_state_change,
    convert(bit,0) opt_state_change
from
    marketing.CSH_Moving_Extended_SKU e
join
    ext.Customer_Status s
on
    (
        e._status = s.ID
    )
where
    (
        s.is_customer = 1
    and s.is_active = 1
    and e.order_date < convert(date,getutcdate()) --
    and e.order_date >= convert(date,dateadd(year,-1,getutcdate())) --
    and e._end_date is null
    )

/* end***/
*/
/* start***/
/*
union all

select
    dateadd(year,1,csh.[Last Order]) csh_start,
    dateadd(year,2,dateadd(day,-1,csh.[Last Order])) csh_end,
    csh.[Last Order] order_date,
    7 csh_status,
    csh.No_ cus,
    null channel_code,
    'out_of_range' sku,
    c.email_optin opt_status,
    dateadd(year,1,csh.[Last Order]) csh_status_start,
    fo.first_order first_order_cus,
    null first_order_range,
    null first_order_sku,
    -1 ecosystem,
    90 _partition,
    1 risk_factor,
    0 risk_days_left,
    -1 opt_source_key,
    convert(bit,0) eco_state_change,
    convert(bit,0) opt_state_change
from
    ext.Customer_Status_History csh
join
    ext.Customer_Status s
on
    (
        csh.[Status] = s.ID
    )
join
    (
        select
            cus,
            min(first_order) first_order
        from
            ext.Customer_Item_Summary
        group by
            cus
    ) fo
on
    csh.No_ = fo.cus
join
    ext.Customer c
on
    (
        csh.No_ = c.cus
    )
where
    (
        s.is_customer = 1
    and s.is_active = 1
    and csh.[Last Order] < convert(date,getutcdate()) --
    and csh.[Last Order] >= convert(date,dateadd(year,-1,getutcdate())) --
    and csh.[End Date] is null
    )
*/
/* end***/

union all

select
    e.[Start Date] csh_start,
    isnull(e.[End Date],case [Status] when 4 then dateadd(year,1,dateadd(day,-1,e.[Start Date])) when 5 then datefromparts(year(getutcdate())+1,12,31) end) csh_end, --
    e.[Last Order] order_date,
    e.[Status] csh_status,
    e.No_ cus,
    null,
    isnull(cis.sku,'out_of_range') sku,
    e.[Opt In] opt_status,
    e.[Status Start Date] csh_status_start,
    null first_order_cus,
    null first_order_range,
    null first_order_sku,
    e.Ecosystem,
    p._partition,
    null,
    null,
    e.opt_source_key,
    e.eco_state_change,
    marketing.fn_opt_in_email_change(e.No_, e.[Start Date], e.[Opt In], e.opt_state_change) opt_state_change
from
    marketing.CSH_Moving_Extended e
left join
    ext.Customer_Item_Summary cis
on
    (
        e.No_ = cis.cus
    and datediff(year,cis.last_order,e.[Start Date]) <= case when e.[Status] = 4 then 1 else 2 end
    )
cross apply
    [db_sys].[model_partition_bi] p
where
    (
        e.[Status] in (4,5)
    and isnull(e.[End Date],convert(date,getutcdate())) >= p.date_start
    and isnull(e.[End Date],convert(date,getutcdate())) <= p.date_end
    )

union all

select
    e._start_date csh_start,
    isnull(e._end_date,datefromparts(year(getutcdate())+1,12,31)) csh_end, --
    null order_date,
    6 csh_status,
    e.cus,
    null channel_code,
    null sku,
    e.email_optin opt_status,
    convert(date,c.[Created Date]) csh_status_start,
    null first_order_cus,
    null first_order_range,
    null first_order_sku,
    null ecosystem,
    14+p._partition,
    null risk_factor,
    null risk_days_left,
    e.opt_source_key,
    convert(bit,0) eco_state_change,
    marketing.fn_opt_in_email_change(e.cus, e._start_date, e.email_optin, 1) opt_state_change
from
    ext.Prospect_OptIn_History e
join
    [dbo].[UK$Customer] c
on
    (
        e.cus = c.No_
    )
cross apply
    [db_sys].[model_partition_bi] p
where
    (
        isnull(e._end_date,convert(date,getutcdate())) >= p.date_start
    and isnull(e._end_date,convert(date,getutcdate())) <= p.date_end
    )
GO
