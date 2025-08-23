CREATE function [stock].[fn_oos_plr]
    (
        @item_id int
    )

returns @oos_plr table 
    (
        id int,
        location_id int,
        is_batch bit,
        is_po bit,
        is_qa bit,
        is_actual bit,
        is_oos bit,
        ref int,
        ldd date,
        erd date, --expected receipt date
        sale_first date,
        sale_last date,
        sale_total int,
        subs_total int,
        open_balance int,
        avail_balance int,
        ring_fenced int,
        not_rf_subs_reserve int default 0,
        on_order int,
        estimated_lost_subs int default 0,
        estimate_cycle int,
        estimate_daily_sales decimal(28,10),
        estimate_total_sales int,
        estimate_close_bal int,
        estimate_open_date date,
        estimate_close_date date,
        forecast_cycle int,
        forecast_daily_sales decimal(28,10),
        forecast_total_sales int,
        forecast_close_bal int,
        forecast_open_date date,
        forecast_close_date date,
        is_end bit,
        is_empty bit default 0
    )

-- as

begin

declare 
    @date_close date = dateadd(day,-1,getdate()),
    @sku nvarchar(20),         
    @item_tracking_code nvarchar(10),
    @daily_dose decimal(28,10),
    @pack_size decimal(28,10),
    @loop_current int = 0, @loop_end int, @ndd date = getdate(),
    @end_date date = datefromparts(year(getutcdate())+4,1,3), 
    @erd date, 
    @runout date, 
    @iteration int = 0, 
    @iteration_end int

select top 1 @sku = No_ from ext.Item where ID = @item_id

declare @subs_list table (id int, location_id int, iteration int, iteration_end int, frq int, ndd date, qty int, is_rf bit default 0, is_oo bit default 0, op_id int, is_end bit default 0)

insert into @subs_list (id, location_id, iteration, iteration_end, frq, ndd, qty, is_rf)
select
    sh.ID,
    (select top 1 ID from ext.Location xx where xx.company_id = l.company_id and xx.subscription_loc = 1),
    0,
    floor(db_sys.fn_divide(datediff(day,isnull(sdm.[Move To Date],l.[Next Delivery Date]),@end_date),l.[Frequency (No_ of Days)],0)),
    l.[Frequency (No_ of Days)] frq, 
    convert(date,isnull(sdm.[Move To Date],l.[Next Delivery Date])) ndd,
    l.Quantity qty,
    case when l.[Status] = 6 then 1 else 0 end
from
    hs_consolidated.[Subscriptions Line] l
join
    ext.Subscriptions_Header sh
on
    (
        l.company_id = sh.company_id
    and l.[Subscription No_] = sh.No_
    )
join
    ext.Item i
on
    (
        l.company_id = i.company_id
    and l.[Item No_] = i.No_
    )
left join
    [hs_consolidated].[Subscription Date Move2] sdm
on
    (
        l.company_id = sdm.company_id
    and l.[Next Delivery Date] = sdm.[Move From Date]
    )
where
    (
        convert(date,isnull(sdm.[Move To Date],l.[Next Delivery Date])) >= dateadd(month,-1,getutcdate())
    and l.[Status] in (0,6)
    and l.[Frequency (No_ of Days)] > 0
    and i.ID = @item_id
    )

select @iteration_end = max(iteration_end) from @subs_list

while @iteration < @iteration_end

    begin

        insert into @subs_list (id, location_id, iteration, iteration_end, frq, ndd, qty)
        select
            id,
            location_id,
            iteration+1,
            iteration_end,
            frq,
            dateadd(day,frq,ndd),
            qty
        from
            @subs_list
        where
            (
                iteration = @iteration
            and iteration < iteration_end
            )

        set @iteration += 1

    end

update
    sl
set
    sl.is_rf = 1
from
    @subs_list sl
join
    (
        select
            sh.ID id,
            row_number() over (partition by sh.ID order by [Expected Delivery Date]) iteration
        from
            hs_consolidated.[Ring Fencing Entry] rfe
        join
            ext.Item i
        on
            (
                rfe.company_id = i.company_id
            and rfe.[Item No_] = i.No_
            )
        join
            ext.Subscriptions_Header sh
        on
            (
                rfe.company_id = sh.company_id
            and rfe.[Subscription No_] = sh.No_
            )
        where
            (
                i.ID = @item_id
            and [Covered by Available Quantity] > 0
            )
    ) rf
on
    (
        sl.id = rf.id
    and sl.iteration = rf.iteration
    )

--oo here
insert into @subs_list (is_oo, location_id, ndd, qty)
select
    1 is_oo,
    el.ID,
    sh.[Order Date],
    sl.[Outstanding Quantity]
from 
    hs_consolidated.[Sales Line] sl
join 
    hs_consolidated.[Sales Header] sh 
on 
    (
        sh.company_id = sl.company_id
    and sh.No_ = sl.[Document No_] 
    and sl.[Document Type] = sh.[Document Type]
    )
join
    ext.Location el
on
    (
        sl.company_id = el.company_id
    and sl.[Location Code] = el.location_code
    )
where 
    (
        sl.No_ = @sku
    and sl.[Outstanding Quantity] > 0
    and sh.[Sales Order Status] = 1
    )

select top 1 @item_tracking_code = [Item Tracking Code], @daily_dose = [Daily Dose], @pack_size = [Pack Size] from hs_consolidated.[Item] where No_ = @sku order by company_id

declare @l table (location_id int, company_id int, grp int, estimate_daily_sales decimal(28,10), location_id_dist int)

insert into @l (location_id, company_id, grp, estimate_daily_sales)
select
    x.ID,
    x.company_id,
    x.grp,
    x.estimate_daily_sales
from
    (
        select
            ID,
            company_id,
            distribution_loc,
            holding_loc,
            dense_rank() over (order by company_id, country, distribution_type) grp,
            case when distribution_loc = 1 then stock.fn_estimate_daily_sales(@item_id,ID,@date_close) else 0 end estimate_daily_sales
        from
            ext.Location
    ) x

update
    l0
set
    l0.location_id_dist = l2.location_id
from
    @l l0
cross apply
    (
        select
            min(estimate_daily_sales) estimate_daily_sales
        from
            @l l1
        where
            (
                l0.grp = l1.grp
            )
    ) l1
cross apply
    (
        select top 1
            location_id
        from
            @l l2
        where
            (
                l0.grp = l2.grp
            and l1.estimate_daily_sales = l2.estimate_daily_sales
            )
    ) l2

update
    l
set
    l.location_id_dist = loa.location_ID_overide
from
    @l l
join
    anaplan.location_overide_aggregate loa
on
    l.location_id_dist = loa.location_id
where
    (
        loa.location_ID_overide != l.location_id_dist
    )

declare @id int, @location_id int, @location_id_previous int, @ref int, @ldd date, @sale_first date, @avail_balance int

declare @estimate_daily_sales decimal(28,10), @estimate_total_sales decimal(28,10), @estimate_close_bal decimal(28,10), @estimate_open_date date, @estimate_close_date date, @estimate_cycle int, @estimate_batch_overflow decimal(28,10) = 0

declare @forecast_daily_sales decimal(28,10), @forecast_total_sales decimal(28,10), @forecast_close_bal decimal(28,10), @forecast_open_date date, @forecast_close_date date, @forecast_cycle int, @forecast_batch_overflow decimal(28,10) = 0

insert into @oos_plr (id, location_id, is_batch, is_po, is_qa, is_actual, is_oos, ref, ldd, open_balance, avail_balance, ring_fenced, not_rf_subs_reserve, on_order, estimate_daily_sales, is_end, estimate_cycle, forecast_cycle, erd, sale_first, sale_last, sale_total, subs_total, is_empty)
select
    row_number() over (order by x.location_id, isnull(x.ldd, x.erd), x.open_balance) * 10,
    x.location_id,
    x.is_batch,
    x.is_po,
    x.is_qa,
    0 is_actual,
    0 is_oos,
    x.ref,
    isnull(x.ldd,datefromparts(2099,12,31)),
    x.open_balance,
    x.open_balance,
    0 ring_fenced,
    0 not_rf_subs_reserve,
    0 on_order,
    x.estimate_daily_sales,
    0 is_end,
    0 estimate_cycle,
    0 forecast_cycle,
    x.erd,
    x.sale_first,
    x.sale_last,
    isnull(x.sale_total,0),
    isnull(x.subs_total,0),
    isnull((select top 1 is_empty from ext.Item_Batch_Info g where x.is_batch = 1 and g.ID = x.ref),0)
from
    (
        select
            ob.location_id,
            1 is_batch,
            0 is_po,
            stock.fn_qa_status_is_qa(ob.ref) is_qa,
            ob.ref,
            ob.open_balance,
            ext.fn_Item_Lifetime_ldd(ob.ref) ldd,
            stock.fn_qa_status_qa_release(ob.ref) erd,
            ob.sale_first,
            ob.sale_last,
            ob.sale_total,
            ob.subs_total,
            l.estimate_daily_sales
        from
            (
                select
                    ile.ref,
                    ile.location_id,
                    ile.open_balance,
                    ile.sale_first,
                    ile.sale_last,
                    ile.sale_total,
                    ile.subs_total
                from
                    (
                        select
                            l.location_id_dist location_id,
                            ibi.ref,
                            min(case when [Entry Type] = 1 and nullif(ile.[Subscription No_],'') is null then ile.[Posting Date] end) sale_first,
                            max(case when [Entry Type] = 1 and nullif(ile.[Subscription No_],'') is null then ile.[Posting Date] end) sale_last,
                            sum(case when [Entry Type] = 1 and nullif(ile.[Subscription No_],'') is null then ile.[Quantity] end) sale_total,
                            sum(case when [Entry Type] = 1 and len(ile.[Subscription No_]) > 0 then ile.[Quantity] end) subs_total,
                            sum(ile.Quantity) open_balance
                        from
                            hs_consolidated.[Item Ledger Entry] ile
                        join
                            ext.Location el
                        on
                            (
                                ile.company_id = el.company_id
                            and ile.[Location Code] = el.location_code
                            )
                        join
                            @l l
                        on
                            (
                                el.ID = l.location_id
                            )
                        join
                            hs_consolidated.[Location] hl
                        on
                            (
                                ile.company_id = hl.company_id
                            and ile.[Location Code] = hl.Code
                            )
                        join
                            (
                                select 
                                    ID ref,
                                    company_id,
                                    sku,
                                    variant_code,
                                    batch_no
                                from 
                                    ext.Item_Batch_Info
                            ) ibi
                        on
                            (
                                ile.company_id = ibi.company_id
                            and ile.[Item No_] = ibi.sku
                            and ile.[Variant Code] = ibi.variant_code
                            and ile.[Lot No_] = ibi.batch_no
                            )
                        where
                            (
                                ile.[Item No_] = @sku
                            and ile.[Posting Date] <= @date_close
                            and hl.[Skip Lot No_ Check] = 0
                            )
                        group by
                            l.location_id_dist,
                            ibi.ref
                    ) ile
            ) ob
        join
            @l l
        on
            (
                ob.location_id = l.location_id_dist
            and l.location_id_dist = l.location_id
            )
        where
            (
                (
                    ob.open_balance = 0
                and ob.sale_first is not null
                )
            or
                (
                    ob.open_balance > 0
                )
            )

        union all

        select
            l1.location_id_dist,
            0 is_batch,
            1 is_po,
            0 is_qa,
            e_pl.ID ref,
            pl.[Outstanding Quantity] open_balance,
            datefromparts(2099,12,31) ldd,
            dateadd(day,5,db_sys.foweek(pl.[Expected Receipt Date],case when hi.[Range Code] = 'ELITE' then 3 when l0.distribution_loc = 1 then 0 else 1 end)) erd,
            null sale_first,
            null sale_last,
            0 sale_total,
            0 subs_total,
            l2.estimate_daily_sales
        from
            [hs_consolidated].[Purchase Header] ph
        join
            [hs_consolidated].[Purchase Line] pl
        on
            (
                ph.company_id = pl.company_id
            and ph.[No_] = pl.[Document No_]
            )
        join
            ext.Purchase_Line e_pl
        on
            (
                pl.company_id = e_pl.company_id
            and pl.[Document Type] = e_pl.[Document Type]
            and pl.[Document No_] = e_pl.[Document No_]
            and pl.[Line No_] = e_pl.[Line No_]
            )
        join
            [hs_consolidated].[Vendor] v
        on
            (
                ph.company_id = v.company_id
            and ph.[Buy-from Vendor No_] = v.[No_]
            )
        join
            [ext].[Item] ei
        on
            (
                pl.company_id = ei.company_id
            and pl.[No_] = ei.[No_]
            )
        join
            hs_consolidated.Item hi
        on
            (
                pl.company_id = hi.company_id
            and pl.[No_] = hi.[No_]
            )
        join
            ext.Location l0
        on
            (
                pl.company_id = l0.company_id
            and pl.[Location Code] = l0.location_code
            )
        join
            @l l1
        on
            (
                l0.ID = l1.location_id
            )
        join
            @l l2
        on
            (
                l1.location_id_dist = l2.location_id_dist
            and l2.location_id_dist = l2.location_id
            )
        where
            (
                ph.[Status] in (1,2)
            and ph.[Status 2] in (2,3)
            and v.[Type of Supply Code] = 'PROCUREMNT'
            and ei.ID = @item_id
            and pl.[Type] = 2
            and pl.[Outstanding Quantity] > 0
            and pl.[Expected Receipt Date] >=  db_sys.foweek(@date_close,0)
            )

    ) x
-- select * from @oos_plr
declare @l_tmp table (location_id int)

declare @op_tmp table (id int, avail_balance int, erd date)

insert into @l_tmp
select distinct
    l.location_id_dist
from
    @subs_list sl
join
    @l l
on
    (
        sl.location_id = l.location_id
    )

while (select isnull(sum(1),0) from @l_tmp) > 0

    begin

    select top 1 @location_id = location_id from @l_tmp

    insert into @op_tmp (id, avail_balance, erd)
    select
        id, avail_balance, erd
    from
        @oos_plr
    where
        (
            location_id = @location_id
        and avail_balance > 0
        )

    while (select isnull(sum(1),0) from @op_tmp) > 0

        begin

        select top 1 @id = id, @avail_balance = avail_balance, @erd = erd from @op_tmp order by id

        update
            x
        set
            x.op_id = @id,
            x.is_end = 1
        from
            (
                select
                    is_end,
                    op_id,
                    is_rf,
                    is_oo,
                    ndd,
                    @avail_balance -  sum(qty) over (order by is_rf desc, ndd rows between unbounded preceding and current row) run_bal
                from
                    @subs_list sl
                where
                    (
                        location_id = @location_id
                    and is_end = 0
                    )
            ) x
        where
            (
                x.run_bal >= 0
            and
                (
                    x.is_rf = 1
                or  x.is_oo = 1
                or  x.ndd < @erd
                )
            )

        delete from @op_tmp where id = @id

        end

    delete from @l_tmp where location_id = @location_id

    end

    update
        op
    set
        op.avail_balance += sl.rf + sl.sub + sl.oo,
        op.ring_fenced += sl.rf,
        op.not_rf_subs_reserve += sl.sub,
        op.on_order += sl.oo
    from
        @oos_plr op
    join
        (
            select
                op_id,
                sum(case when is_rf = 1 then -qty else 0 end) rf,
                sum(case when is_rf = 0 and is_oo = 0 then -qty else 0 end) sub,
                sum(case when is_oo = 1 then -qty else 0 end) oo
            from
                @subs_list
            where
                is_end = 1
            group by
                op_id
        ) sl
    on
        (
            op.id = sl.op_id
        )

set @estimate_open_date = dateadd(day,1,@date_close)

set @forecast_open_date = dateadd(day,1,@date_close)

while (select isnull(sum(1),0) from @oos_plr where avail_balance > 0 and is_end = 0) > 0

    begin

    select top 1 
        @id = id,
        @location_id = location_id, 
        @ref = ref,
        @ldd = ldd,
        @erd = erd,
        @sale_first = sale_first,
        @avail_balance = avail_balance, 
        @estimate_close_bal = avail_balance, 
        @estimate_daily_sales = estimate_daily_sales, 
        @estimate_cycle = estimate_cycle,
        @forecast_close_bal = avail_balance,
        @forecast_cycle = forecast_cycle
    from 
        @oos_plr 
    where
        (
            avail_balance > 0
        and is_end = 0
        )
    order by 
        id

    if @location_id != @location_id_previous set @estimate_open_date = dateadd(day,1,@date_close)

    if @location_id != @location_id_previous set @forecast_open_date = dateadd(day,1,@date_close)

    if @erd is not null and @erd > @estimate_open_date set @estimate_open_date = @erd 

    if @erd is not null and @erd > @forecast_open_date set @forecast_open_date = @erd

    if @location_id != @location_id_previous set @estimate_batch_overflow = 0
    
    if @location_id != @location_id_previous set @forecast_batch_overflow = 0

    set @estimate_close_date = @estimate_open_date

    set @forecast_close_date = @forecast_open_date

    set @estimate_total_sales = 0

    set @forecast_total_sales = 0

    while @estimate_close_date < @ldd and @estimate_close_bal > 0 

        begin

            set @estimate_close_date = dateadd(day,1,@estimate_close_date)

            set @estimate_total_sales += @estimate_daily_sales

            set @estimate_total_sales += @estimate_batch_overflow

            set @estimate_close_bal += @estimate_daily_sales

            set @estimate_close_bal += @estimate_batch_overflow

            set @estimate_batch_overflow = 0

            if @estimate_close_bal < 0 
                
                begin 
                
                    set @estimate_total_sales = @estimate_total_sales - @estimate_close_bal 

                    set @estimate_batch_overflow = @estimate_close_bal

                    set @estimate_close_bal = 0
                    
                end

            set @estimate_cycle += 1

        end

    while @forecast_close_date < @ldd and @forecast_close_bal > 0

        begin

            select
                @forecast_daily_sales = isnull(sum(-r.dow_split),0)
            from
                anaplan.forecast f
            cross apply
                stock.fn_forecast_ratio(f.quantity,default) r
            where
                (
                    f.is_current = 1
                and f._location = @location_id
                and f.sku = @item_id
                and f._year = datepart(year,@forecast_close_date)
                and f._week = datepart(week,@forecast_close_date)
                and r.dow = datepart(dw,@forecast_close_date)
                )

            select @forecast_daily_sales += isnull(sum(-1),0) from @subs_list where ndd = @forecast_close_date

            set @forecast_close_date = dateadd(day,1,@forecast_close_date)

            set @forecast_total_sales += @forecast_daily_sales

            set @forecast_total_sales += @forecast_batch_overflow

            set @forecast_close_bal += @forecast_daily_sales

            set @forecast_close_bal += @forecast_batch_overflow

            set @forecast_batch_overflow = 0

            if @forecast_close_bal < 0 
            
                begin
                
                    set @forecast_total_sales = @forecast_total_sales - @forecast_close_bal

                    set @forecast_batch_overflow = @forecast_close_bal

                    set @forecast_close_bal = 0

                end

            set @forecast_cycle += 1

        end

    update 
        @oos_plr 
    set 
        estimate_open_date = (select min(x._date) from (values (@estimate_open_date),(@sale_first)) x (_date)),
        estimate_close_date = @estimate_close_date,
        estimate_close_bal = db_sys.fn_round_by_sample(@avail_balance,@estimate_close_bal),
        estimate_cycle = @estimate_cycle,
        estimate_total_sales = @estimate_total_sales,
        forecast_open_date = (select min(x._date) from (values (@forecast_open_date),(@sale_first)) x (_date)),
        forecast_close_date = @forecast_close_date,
        forecast_close_bal = db_sys.fn_round_by_sample(@avail_balance,@forecast_close_bal),
        forecast_cycle = @forecast_cycle,
        forecast_daily_sales = db_sys.fn_divide(@forecast_total_sales,@forecast_cycle,0),
        forecast_total_sales = @forecast_total_sales,
        is_end = 1 
    where
        (
            id = @id
        )

    set @estimate_open_date = @estimate_close_date

    set @forecast_open_date = @forecast_close_date

    set @location_id_previous = @location_id

    end

update
    @oos_plr
set
    is_actual = 1,
    estimate_daily_sales = db_sys.fn_divide(sale_total,datediff(day,sale_first,sale_last),0),
    estimate_total_sales = sale_total,
    estimate_close_bal = avail_balance,
    estimate_open_date = sale_first,
    estimate_close_date = sale_last,
    forecast_daily_sales = db_sys.fn_divide(sale_total,datediff(day,sale_first,sale_last),0),
    forecast_total_sales = sale_total,
    forecast_close_bal = avail_balance,
    forecast_open_date = sale_first,
    forecast_close_date = sale_last
where 
    (
        avail_balance = 0 --was open_balance
    )

insert into @oos_plr (id, location_id, is_batch, is_po, is_qa, is_actual, is_oos, ref, sale_total, subs_total, open_balance, avail_balance, ring_fenced, on_order, estimate_cycle, estimate_daily_sales, estimate_close_bal, estimate_open_date, estimate_close_date, forecast_cycle, forecast_daily_sales, forecast_close_bal, forecast_open_date, forecast_close_date, is_end, is_empty)
select
    id+1,
    location_id,
    is_batch,
    is_po,
    0 is_qa,
    0 is_actual,
    1 is_oos,
    ref,
    0 sale_total,
    0 subs_total,
    -- isnull
    --     (
    --         db_sys.fn_round_by_sample
    --             (
    --                     subs_total,db_sys.fn_divide
    --                         (
    --                             subs_total,datediff
    --                                 (
    --                                     day,sale_first,sale_last
    --                                 ),0
    --                         )*
    --                         (
    --                             select 
    --                                 min
    --                                     (
    --                                         cycle
    --                                     ) 
    --                             from 
    --                                 (
    --                                     values 
    --                                         (
    --                                             datediff
    --                                                 (
    --                                                     day,estimate_open_date,dateadd
    --                                                         (
    --                                                             day,-1,@date_close
    --                                                         )
    --                                                 )
    --                                         ),
    --                                         (
    --                                             estimate_cycle
    --                                         )
    --                                 ) x 
    --                                 (
    --                                     cycle
    --                                 )
    --                         )
    --                 ),0
    --         )-
    --     isnull
    --         (
    --             case when id = id_last then 
    --                 (
    --                     select sum(1) from @rf rf where rf.location_id = t.location_id and rf.is_end = 0
    --                 ) end,0
    --         ) subs_total, ---??? 
    0 open_balance,
    0 avail_balance,
    -- isnull(case when id = id_last then (select sum(1) from @rf rf where rf.location_id = t.location_id and rf.is_end = 0) end,0) 
    0 ring_fenced,
    -- isnull(case when id = id_last then (select sum(1) from @oo oo where oo.location_id = t.location_id and oo.is_end = 0) end,0) on_order,
    0 on_order,
    estimate_cycle,
    estimate_daily_sales-1,
    0,
    dateadd(day,0,estimate_open_date),
    isnull(n.next_erd,n.next_eod) estimate_close_date,
    forecast_cycle,
    forecast_daily_sales-1,
    0,
    dateadd(day,0,forecast_open_date),
    isnull(n.next_erd,n.next_fod) forecast_close_date,
    0 is_end,
    t.is_empty
from
    (
        select
            id,
            max(id) over (partition by location_id) id_last,
            location_id,
            is_batch,
            is_po,
            ref,
            subs_total,
            sale_first,
            sale_last,
            is_oos,
            db_sys.fn_minus_min0
                (
                    datediff
                        (
                            day,estimate_close_date,isnull(lead(estimate_open_date) over (partition by location_id order by id),datefromparts(year(@date_close)+1,12,31))
                        )
                )-1 estimate_cycle,
            estimate_daily_sales,
            estimate_close_date estimate_open_date,
            db_sys.fn_minus_min0
                (
                    datediff
                        (
                            day,forecast_close_date,isnull(lead(forecast_open_date) over (partition by location_id order by id),datefromparts(year(@date_close)+1,12,31))
                        )
                )-1 forecast_cycle,
            forecast_daily_sales,
            forecast_close_date forecast_open_date,
            is_empty
        from 
            @oos_plr
    ) t
outer apply
    (
        select top 1
            k.estimate_open_date next_eod,
            k.forecast_open_date next_fod,
            k.erd next_erd
        from
            @oos_plr k
        where
            t.id < k.id
        order by
            k.id --coalesce(k.erd,k.sale_first,k.estimate_open_date,k.forecast_open_date) 
    ) n
where
    (
        (
            t.estimate_open_date <= coalesce(n.next_eod,n.next_erd,datefromparts(year(@date_close)+1,12,31))
        or  t.forecast_open_date <= coalesce(n.next_fod,n.next_erd,datefromparts(year(@date_close)+1,12,31))
        )
    and
        (
            datediff(day,t.estimate_open_date,coalesce(n.next_eod,n.next_erd,datefromparts(year(@date_close)+1,12,31))) > 5
        or  datediff(day,t.forecast_open_date,coalesce(n.next_fod,n.next_erd,datefromparts(year(@date_close)+1,12,31))) > 5
        )
    )
order by 
    id

update
    @oos_plr
set
    estimate_close_date = estimate_open_date
where
    (
        estimate_close_date < estimate_open_date
    )

update
    @oos_plr
set
    forecast_close_date = forecast_open_date
where
    (
        forecast_close_date < forecast_open_date
    )

while (select isnull(sum(1),0) from @oos_plr where is_oos = 1 and is_end = 0) > 0

begin

    select top 1
        @id = id,
        @location_id = location_id,
        @estimate_daily_sales = estimate_daily_sales,
        @estimate_cycle = estimate_cycle,
        @estimate_open_date = estimate_open_date,
        @forecast_daily_sales = forecast_daily_sales,
        @forecast_cycle = forecast_cycle,
        @forecast_open_date = forecast_open_date
    from
        @oos_plr t
    where
        (
            t.is_oos = 1
        and t.is_end = 0
        )
    order by
        id

    set @forecast_total_sales = 0

    while @forecast_cycle > 0

        begin

        select
                @forecast_daily_sales = isnull(sum(-r.dow_split),@forecast_daily_sales)
            from
                anaplan.forecast f
            cross apply
                stock.fn_forecast_ratio(f.quantity,default) r
            where
                (
                    f.is_current = 1
                and f._location = @location_id
                and f.sku = @item_id
                and f._year = datepart(year,@forecast_open_date)
                and f._week = datepart(week,@forecast_open_date)
                and r.dow = datepart(dw,@forecast_open_date)
                )

        set @forecast_cycle = @forecast_cycle - 1

        set @forecast_open_date = dateadd(day,1,@forecast_open_date)

        set @forecast_total_sales = @forecast_total_sales + @forecast_daily_sales

        end
        
    update
        @oos_plr
    set
        is_end = 1,
        estimate_total_sales = db_sys.fn_round_by_sample(ring_fenced,(@estimate_daily_sales*@estimate_cycle)),
        forecast_daily_sales = db_sys.fn_divide(@forecast_total_sales,forecast_cycle,0),
        forecast_total_sales = db_sys.fn_round_by_sample(ring_fenced,@forecast_total_sales)
    where
        id = @id

end

update @oos_plr set ldd = null where ldd = datefromparts(2099,12,31)

-- update
--     t
-- set
--     t.subs_total = t.subs_total + isnull(ss.qty,0)
-- from
--     @oos_plr t
-- cross apply
--     (
--         select
--             sum(-1) qty
--         from
--             @ss ss
--         where
--             (
--                 t.location_id = ss.location_id
--             and ss.ndd > t.estimate_open_date
--             and ss.ndd < t.estimate_close_date
--             and ss.is_end = 0
--             )
--     ) ss
-- where
--     (
--         t.is_oos = 0
--     )

-- update
--     t
-- set
--     t.estimated_lost_subs = isnull(ss.qty,0),
--     t.subs_total = t.subs_total + isnull(ss.qty,0)
-- from
--     @oos_plr t
-- cross apply
--     (
--         select
--             sum(-1) qty
--         from
--             @ss ss
--         where
--             (
--                 t.location_id = ss.location_id
--             and ss.ndd > t.estimate_open_date
--             and ss.ndd < t.estimate_close_date
--             and ss.iteration > 1
--             )
--     ) ss
-- where
--     (
--         t.is_oos = 1
--     )

return

end
GO
