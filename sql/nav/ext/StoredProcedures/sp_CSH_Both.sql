create or alter procedure [ext].[sp_CSH_Both]

as

set nocount on

-- differential flags for _static & _moving
-- iterate through customers individually rather than attempting to merge all at once
-- add exec marketing.sp_Customer_Status_History_prefEmail
-- add end date population for moving window, maintain [marketing].[CSH_Moving_Extended], maintain 
-- updated UpdatedTSUTC when [End Date] is populated
-- addition of [Status End Date]/end_date_status - cross apply was running from [Status Start Date] to [End Date], should be be [Status End Date]
-- rem exec marketing.sp_Customer_Status_History_prefEmail (ref ), data source no longer required and e-mail preference detail part of newer function marketing.fn_CSH_Moving_Extended
-- add procedures [ext].[sp_Customer_Item_Summary] & [ext].[sp_first_order_range]
-- add new columns to CSH_Moving_Extended & CSH_Moving_Extended_SKU : opt_source_key, eco_state_change, opt_state_change
-- populate first_order_sku
-- active from to start from first point customer became active, i.e. either from point of being new or lapsed/reactivated not just from the point of being placed into an active state
-- optimisations to procedure and data, order_date now aggregates to last order rather then every order, replaced function marketing.fn_SalesOrders with subquery
-- add corruption handling (overlaps in timeline between different states - suspect this is triggered by cancelled orders)
-- add customer new states from 1 (new) and 3 (lapsed/reactivated) after 1 year to moving state
-- remove exec db_sys.sp_auditLog_procedure @procedureName='[ext].[sp_Customer_Item_Summary]',@parent_procedureName='[ext].[sp_CSH_Both]' -- - add to db_sys.procedure_schedule_pairing

-- exec db_sys.sp_auditLog_procedure @procedureName='[ext].[sp_Customer_Item_Summary]',@parent_procedureName='[ext].[sp_CSH_Both]' --

declare @x table (No_ nvarchar(20), _static bit, _moving bit)

-- ***start***
declare @corrupt table (cus nvarchar(20))

insert into @corrupt (cus)
select distinct
    x.No_ 
from 
    ext.Customer_Status_History x 
cross apply
    ext.Customer_Status_History y
where 
    (
        x.No_ = y.No_
    and x.[Start Date] > y.[Start Date]
    and x.[End Date] <= y.[End Date]
    )

delete from ext.Customer_Status_History where No_ in (select cus from @corrupt)
-- ***end***

insert into @x (No_, _static, _moving)

select cus, 0, 1 from @corrupt -- (adds clean history back)

union

select No_, 0, 1 from ext.Customer_Status_History where [Status] in (1,3) and [End Date] is null and dateadd(year,1,[Start Date]) < convert(date,getutcdate()) --

union

select [Sell-to Customer No_] No_, 1, 1 from ext.Sales_Header where company_id = 1 and [Sales Order Status] = 1

union

select [Sell-to Customer No_], 0, 1 from ext.Sales_Header_Archive a left join (select No_, max([Last Order]) lo from ext.Customer_Status_History group by No_) h on a.[Sell-to Customer No_] = h.No_ where company_id = 1 and (h.No_ is null or a.[Order Date] > h.lo)

union

select [Sell-to Customer No_], 1, 0 from ext.Sales_Header_Archive a left join (select No_, max([Last Order]) lo from ext.CSH_Static_Window group by No_) h on a.[Sell-to Customer No_] = h.No_ where company_id = 1 and (h.No_ is null or a.[Order Date] > h.lo)

union

select
    h.No_, 0, 1
from
    (
        select No_, max([Start Date]) [Start Date] from ext.Customer_Status_History group by No_
    ) le
join
    ext.Customer_Status_History h
on
    (
        le.No_ = h.No_
    and le.[Start Date] = h.[Start Date]
    )
where
    (
        (
            h.Status = 4
        and dateadd(year,2,h.[Last Order]) < convert(date,getutcdate())
        )
    )

/* start - changes status of inactive customers (customers previously active who have not shopped in a year*/
union

select
    h.No_, 0, 1
from
    (
        select No_, max([Start Date]) [Start Date] from ext.Customer_Status_History group by No_
    ) le
join
    ext.Customer_Status_History h
on
    (
        le.No_ = h.No_
    and le.[Start Date] = h.[Start Date]
    )
where
    (
        (
            h.Status < 4
        and dateadd(year,1,h.[Last Order]) < convert(date,getutcdate())
        )
    )
/* end*/

/* start - sets inactive status for static window logic*/
union

select 
    h.No_, 1, 0
from
    (
        select No_, max([Start Date]) [Start Date] from ext.CSH_Static_Window group by No_
    ) le
join
    ext.CSH_Static_Window h
on
    (
        le.No_ = h.No_
    and le.[Start Date] = h.[Start Date]
    )
where
    (
        (
            (
                h.Status < 4
            and year(h.[Last Order]) + 1 < year(getutcdate())
            )
        or
            (
                h.Status = 4
            and year(h.[Last Order]) + 2 < year(getutcdate())
            )
        )
    )
/* end*/

union

select isnull(m.No_,s.No_), case when s.No_ is null then 1 else 0 end, case when m.No_ is null then 1 else 0 end from ext.Customer_Status_History m full join ext.CSH_Static_Window s on m.No_ = s.No_ where m.No_ is null or s.No_ is null

declare @cus nvarchar(20)

declare moving cursor for select No_ from @x where _moving = 1

open moving

fetch next from moving into @cus

while @@fetch_status = 0

begin

merge ext.Customer_Status_History t
using
    (
    select 
        @cus No_,
        y.event_date,
        y.customer_status,
        y.last_order
    from
        ext.fn_Customer_Status_History(@cus) y
    ) s
on
    (
        t.No_ = s.No_
    and t.[Start Date] = s.event_date
    )
when matched and t.[Last Order] < s.last_order and t.[End Date] is null then update set
    t.[Status] = s.customer_status, t.[Last Order] = s.last_order, t.UpdatedTSUTC = getutcdate()
when not matched by target then insert
    ([No_], [Start Date], [Status], [Last Order]) values (s.No_, s.event_date, s.customer_status, s.last_order);

fetch next from moving into @cus

end

close moving
deallocate moving

-- ***START*** maintain end date on moving
declare @rc int = 1

while @rc > 0

    begin

    update csh set
        csh.[End Date] = ed2.ed,
        csh.UpdatedTSUTC = getutcdate() --
    from
        (
        select top 100000
            No_,
            [Start Date],
            ed
        from
            (
            select 
                No_,
                [Start Date]
                ,dateadd(day,-1,lead(h.[Start Date]) over (partition by h.No_ order by h.[Start Date])) ed
            from
                ext.Customer_Status_History h
            where
                [End Date] is null
            ) ed
        where
            ed.ed is not null
        ) ed2
    join
        ext.Customer_Status_History csh
    on
        (
            ed2.No_ = csh.No_
        and ed2.[Start Date] = csh.[Start Date]
        )

    select @rc = @@rowcount

    end

set @rc = 1

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
                select top 4000 
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
                    (
                        Merged_CSH_Moving_Extended_TSUTC is null
                    or  AddedTSUTC > Merged_CSH_Moving_Extended_TSUTC
                    or  UpdatedTSUTC > Merged_CSH_Moving_Extended_TSUTC
                    )
                -- and [End Date] is null
                )
            ) h
        outer apply
            marketing.fn_CSH_Moving_Extended(h.No_, h.[Start Date],h.[End Date]) e

        union

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
                select top 1000 
                    No_, 
                    [Status], 
                    [Last Order], 
                    [Start Date], 
                    [End Date], 
                    Merged_CSH_Moving_Extended_TSUTC, 
                    AddedTSUTC, 
                    UpdatedTSUTC 
                from 
                    ext.Customer_Status_History h
                join
                    (
                        select [Customer No_], max([Modified DateTime]) [Modified DateTime] from [UK$Customer Preferences Log] where [Record Code] = 'EMAIL' group by [Customer No_]
                    ) p_em
                on
                    (
                        h.No_ = p_em.[Customer No_]
                    )
                where
                    (
                        h.[End Date] is null
                    and h.Merged_CSH_Moving_Extended_TSUTC < p_em.[Modified DateTime]
                    )
            ) h
        outer apply
           marketing.fn_CSH_Moving_Extended(h.No_, h.[Start Date], h.[End Date]) e
        

        set @rc = @@rowcount

        insert into marketing.csh_opt_source (opt_source, opt_source_clean)
        select distinct opt_source, opt_source from [stg].[CSH_Moving_Extended] where len(opt_source) > 0 and opt_source not in (select opt_source from marketing.csh_opt_source)

        delete from [marketing].[CSH_Moving_Extended] where exists (select 1 from [stg].[CSH_Moving_Extended] s where CSH_Moving_Extended.No_ = s.No_ and (CSH_Moving_Extended.[Status Start Date] = s.[Status Start Date] or CSH_Moving_Extended.[Start Date] = s.[Start Date]))
        
        insert into [marketing].[CSH_Moving_Extended] ([No_], [Start Date], [End Date], [Status], [Last Order], [Opt In], [Ecosystem], [Status Start Date], [Status End Date],opt_source_key,eco_state_change,opt_state_change)
        select [No_], [Start Date], [End Date], [Status], [Last Order], [Opt In], [Ecosystem], [Status Start Date], [Status End Date], marketing.fn_csh_opt_source_lookup(opt_source), eco_state_change, opt_state_change  from [stg].[CSH_Moving_Extended]

        delete from [marketing].[CSH_Moving_Extended_SKU] where exists (select 1 from [stg].[CSH_Moving_Extended] s where CSH_Moving_Extended_SKU.cus = s.No_ and (CSH_Moving_Extended_SKU._start_date_status = s.[Status Start Date] or CSH_Moving_Extended_SKU._start_date = s.[Start Date]))

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
                                            h.company_id = l.company_id
                                        and h.No_ = l.[Document No_]
                                        and h.[Document Type] = l.[Document Type]
                                        )
                                    where
                                        (
                                            h.company_id = 1
                                        and h.[Sales Order Status] = 1
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
                                            h.company_id = l.company_id
                                        and h.No_ = l.[Document No_]
                                        and h.[Document Type] = l.[Document Type]
                                        and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
                                        and h.[Version No_] = l.[Version No_]
                                        )
                                    where
                                        (
                                            h.company_id = 1
                                        and h.[Sell-to Customer No_] = cus_status.No_
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

-- ***END***

declare _static cursor for select No_ from @x where _static = 1

open _static

fetch next from _static into @cus

while @@fetch_status = 0

begin

merge ext.CSH_Static_Window t
using
    (
    select 
        @cus No_,
        y.event_date,
        y.customer_status,
        y.last_order
    from
        ext.fn_CSH_Static_Window(@cus) y -- fixed, was pointing at Moving Window Function!
    ) s
on
    (
        t.No_ = s.No_
    and t.[Start Date] = s.event_date
    )
when matched and t.[Last Order] < s.last_order then update set
    t.[Status] = s.customer_status, t.[Last Order] = s.last_order, t.UpdatedTSUTC = getutcdate()
when not matched by target then insert
    ([No_], [Start Date], [Status], [Last Order]) values (s.No_, s.event_date, s.customer_status, s.last_order);

fetch next from _static into @cus

end

close _static
deallocate _static

GO