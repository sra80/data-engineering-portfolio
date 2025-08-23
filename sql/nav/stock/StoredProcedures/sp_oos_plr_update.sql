create or alter procedure [stock].[sp_oos_plr_update]

as

set nocount on

declare @loop_start datetime2(0), @intraday_runtime_limit int = 8 --in minutes

declare @t table (item_id int)

declare @s table (item_id int) --subs with assembly type replenishment system

insert into @s (item_id)
select distinct
    e_i.ID 
from 
    hs_consolidated.[Subscriptions Line] h_sl
join
    ext.Item e_i
on
    (
        h_sl.company_id = e_i.company_id
    and h_sl.[Item No_] = e_i.No_
    )
join
    hs_consolidated.Item h_i
on
    (
        e_i.company_id = h_i.company_id
    and e_i.No_ = h_i.No_
    )
where 
    (
        h_sl.[Next Delivery Date] >= dateadd(month,-1,sysdatetime())
    and h_i.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
    and h_i.[Replenishment System] = 3
    )

declare @item_id int, @row_version int, @addTS_start datetime2(3) = sysdatetime(), @is_intraday bit = 0, @build_new_request bit

select
    @is_intraday = case when datediff(day,db_sys.fn_datetime_utc_to_eest(rv_sub_TS),db_sys.fn_datetime_utc_to_eest(getutcdate())) = 0 then 1 else 0 end,
    @build_new_request = case when build_new_request is null then 0 else 1 end
from
    stock.forecast_subscriptions_version
where
    is_current = 1

if @is_intraday = 0

    begin

        if datepart(dw,db_sys.fn_datetime_utc_to_eest(getutcdate())) = 7 or @build_new_request = 1

            begin
            
                set @row_version = next value for stock.sq_forecast_subscriptions_version

                update stock.forecast_subscriptions_version set is_current = 0 where is_current = 1

                insert into stock.forecast_subscriptions_version (row_version, addTS_start, addTS_end, rv_sub_TS, is_current)
                values (@row_version, @addTS_start, @addTS_start, @addTS_start, 1)

            end

        else

            begin

                set @row_version = -1

                update stock.forecast_subscriptions_version set rv_sub_TS = @addTS_start where is_current = 1

            end

        insert into stock.oos_plr_queue (item_id)
        select
            w.item_id
        from
            (
                select 
                    s_fc.item_id
                from
                    (
                        select
                            item_id,
                            round(sum(quantity)*db_sys.fn_poweek(default),0) forecast
                        from
                            stock.forecast_current
                        where
                            (
                                datepart(year,_date) = datepart(year,getutcdate())
                            and datepart(week,_date) = datepart(week,getutcdate())
                            )
                        group by
                            item_id
                        having
                            sum(quantity) > 0
                    ) s_fc
                cross apply
                    (
                        select
                            sum(x.actual) actual
                        from
                            (
                                select
                                    l.Quantity actual
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
                                cross apply
                                    (
                                        select
                                            min(ID) item_id
                                        from
                                            ext.Item
                                        where
                                            l.No_ = Item.No_
                                    ) i
                                where
                                    (
                                        h.[Sales Order Status] = 1
                                    and datepart(year,h.[Order Date]) = datepart(year,getutcdate())
                                    and datepart(week,h.[Order Date]) = datepart(week,getutcdate())
                                    and s_fc.item_id = i.item_id
                                    and h.[Channel Code] != 'REPEAT'
                                    )

                                union all

                                select
                                    l.Quantity actual
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
                                cross apply
                                    (
                                        select
                                            min(ID) item_id
                                        from
                                            ext.Item
                                        where
                                            l.No_ = Item.No_
                                    ) i
                                where
                                    (
                                        datepart(year,h.[Order Date]) = datepart(year,getutcdate())
                                    and datepart(week,h.[Order Date]) = datepart(week,getutcdate())
                                    and s_fc.item_id = i.item_id
                                    and h.[Channel Code] != 'REPEAT'
                                    )
                            ) x
                    ) actual
                join
                    ext.Item i
                on
                    (
                        s_fc.item_id = i.ID
                    )
                join
                    hs_consolidated.Item ii
                on
                    (
                        i.company_id = ii.company_id
                    and i.No_ = ii.No_
                    )
                where
                    (
                        ii.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
                    and ii.[Replenishment System] in (0,1)
                    and (
                            db_sys.fn_divide(actual.actual-s_fc.forecast,s_fc.forecast,0) > 0.15
                        or  @row_version > -1
                        )
                    )
            ) w
        left join
            stock.oos_plr_queue s_opq
        on
            (
                w.item_id = s_opq.item_id
            )
        where
            (
                s_opq.item_id is null
            )

    end

else --@is_intraday = TRUE

    begin

    --purchase header changes
    insert into stock.oos_plr_queue (item_id)
    select
        p.item_id
    from
        (
            select distinct
                item.item_id
            from 
                ext.Purchase_Header ph
            join
                hs_consolidated.[Purchase Line] pl
            on
                (
                    ph.company_id = pl.company_id
                and ph.[Document Type] = pl.[Document Type]
                and ph.[No_] = pl.[Document No_]
                )
            cross apply
                (
                    select
                        min(ID) item_id
                    from
                        ext.Item i
                    where
                        (
                            pl.No_ = i.No_
                        )
                ) item
            where 
                (
                    ph.queue_oos_plr = 1
                and pl.[Type] = 2
                )
        ) p
    left join
        stock.oos_plr_queue s_opq
    on
        (
            p.item_id = s_opq.item_id
        )
    where
        (
            s_opq.item_id is null
        and p.item_id is not null
        )

    update ext.Purchase_Header set queue_oos_plr = 0 where queue_oos_plr = 1

    --ring fence changes
    declare @i table (item_id int, ringfenced_until date)

    insert into @i (item_id, ringfenced_until)
    select
        e_i.ID,
        h_i.[Ring Fencing Until Date] ringfenced_until
    from
        ext.Item e_i
    join
        hs_consolidated.Item h_i
    on
        (
            e_i.company_id = h_i.company_id
        and e_i.No_ = h_i.No_
        )
    where
        (
            nullif(h_i.[Ring Fencing Until Date],datefromparts(1753,1,1)) != isnull(e_i.ringfenced_until,datefromparts(1753,1,1))
        and h_i.[Ring Fencing Until Date] > dateadd(week,1,getutcdate())
        )

    update
        e_i
    set
        e_i.ringfenced_until = i.ringfenced_until
    from
        ext.Item e_i
    join
        @i i
    on
        (
            e_i.ID = i.item_id
        )

    insert into stock.oos_plr_queue (item_id)
    select distinct
        i.item_id
    from
        @i i
    left join
        stock.oos_plr_queue s_opq
    on
        (
            i.item_id = s_opq.item_id
        )
    where
        (
            s_opq.item_id is null
        )

    update
        e_i
    set
        e_i.ringfenced_until = null
    from
        ext.Item e_i
    join
        hs_consolidated.Item h_i
    on
        (
            e_i.company_id = h_i.company_id
        and e_i.No_ = h_i.No_
        )
    where
        (
            h_i.[Ring Fencing Until Date] = datefromparts(1753,1,1)
        and ringfenced_until > datefromparts(1753,1,1)
        )

    --qa changes
    insert into stock.oos_plr_queue (item_id)
    select distinct
        op.item_id
    from
        stock.oos_plr op
    left join
        stock.oos_plr_queue q
    on
        (
            op.item_id = q.item_id
        )
    cross apply
        stock.fn_qa_status(op.ref) qa
    where
        (
            op.row_version = (select row_version from stock.forecast_subscriptions_version where is_current = 1)
        and op.rv_sub = 0
        and op.is_batch = 1
        and (
                op.erd != qa.expected_release
            or  op.is_qa != qa.is_qa
            or  op.is_stop != qa.is_stop
            )
        and q.item_id is null
        )

    set @row_version = -1

    update stock.forecast_subscriptions_version set intraday_TS = getutcdate() where is_current = 1

    end

delete from t from stock.oos_plr_queue t join ext.Item e_i on t.item_id = e_i.ID join hs_consolidated.Item h_i on e_i.company_id = h_i.company_id and e_i.No_ = h_i.No_ where (h_i.[Replenishment System] > 1 and t.item_id not in (select item_id from @s)) or h_i.[Inventory Posting Group] not in ('FINISHED','B2B ITEMS')

insert into stock.oos_plr_queue (item_id)
select distinct
    ii.ID
from
    stock.oos_plr_queue s
join
    ext.Item i
on
    (
        s.item_id = i.ID
    )
join
    hs_consolidated.[BOM Component] bc
on
    (
        i.company_id = bc.company_id
    and i.No_ = bc.[Parent Item No_]
    )
join
    ext.Item ii
on
    (
        bc.company_id = ii.company_id
    and bc.[No_] = ii.No_
    )
where
    (
        ii.ID not in (select item_id from stock.oos_plr_queue)
    )

set @loop_start = getutcdate()

while (select isnull(sum(1),0) from stock.oos_plr_queue) > 0 and @is_intraday = 0 or (datepart(hour,db_sys.fn_datetime_utc_to_gmt(default)) < 9 and datepart(hour,db_sys.fn_datetime_utc_to_gmt(default)) > 17 and datediff(minute,@loop_start,getutcdate()) <= @intraday_runtime_limit)

    begin

        select top 1 @item_id = item_id from stock.oos_plr_queue order by addTS

        exec stock.sp_oos_plr @item_id = @item_id, @row_version = @row_version

    end

if @is_intraday = 0 and @row_version > -1

    begin

        update stock.forecast_subscriptions_version set addTS_end = sysdatetime() where row_version = @row_version

    end