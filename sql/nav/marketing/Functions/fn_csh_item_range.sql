create or alter function marketing.fn_csh_item_range
    (
        @customer_id int
    )

returns table

as

return

    (
        with orders (range_id, date_start) as
            (
                select
                    a.range_id,
                    a.date_start
                from
                    (
                        select distinct 
                            nav_id 
                        from 
                            hs_identity.Customer 
                        where 
                            (
                                customer_id = @customer_id
                            )
                    ) c
                join
                    hs_identity_link.Customer_NAVID n
                on
                    (
                        c.nav_id = n.ID
                    )
                cross apply
                    (
                        select
                            r.ID range_id,
                            convert(date,h.[Order Date]) date_start
                        from
                            hs_consolidated.[Sales Header Archive] h
                        join
                            hs_consolidated.[Sales Line Archive] l
                        on
                            (
                                h.company_id = l.company_id
                            and h.[Document Type] = l.[Document Type]
                            and h.[No_] = l.[Document No_]
                            and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
                            and h.[Version No_] = l.[Version No_]
                            )
                        join
                            hs_consolidated.Item i
                        on
                            (
                                i.company_id = 1
                            and l.No_ = i.No_
                            )
                        join
                            ext.Range r
                        on
                            (
                                i.company_id = r.company_id
                            and i.[Range Code] = r.range_code
                            )
                        where
                            (
                                h.company_id = n.company_id
                            and h.[Sell-to Customer No_] = n.nav_code
                            and h.[Archive Reason] = 3
                            and i.[Type] = 0
                            )

                        union

                        select
                            r.ID,
                            s.order_date
                        from
                            scv.sales s
                        join
                            hs_consolidated.Item i
                        on
                            (
                                i.company_id = 1
                            and s.sku = i.No_
                            )
                        join
                            ext.Range r
                        on
                            (
                                i.company_id = r.company_id
                            and i.[Range Code] = r.range_code
                            )
                        where
                            (
                                n.company_id = 1
                            and s.cus = n.nav_code
                            and i.[Type] = 0
                            )  
                    ) a
            )
        , add_main (range_id, date_start) as
            (
                select
                    orders.range_id,
                    orders.date_start
                from
                    orders

                union

                select
                    42,
                    orders.date_start
                from
                    orders
            )
        , add_end (range_id, date_start, date_end) as
            (
                select
                    x.range_id,
                    x.date_start,
                    dateadd(day,-1,(select min(m._date) from (values (x.date_end),(dateadd(year,1,x.date_start))) as m(_date)))
                from
                    (
                        select
                            range_id,
                            date_start,
                            lead(date_start) over (partition by range_id order by date_start) date_end
                        from
                            add_main
                    ) x
            )
        , add_status (range_id, date_start, date_end, _status) as
            (
                select
                    gap.range_id,
                    gap.date_start,
                    case 
                        when 
                            (
                                gap.gap is null
                            or  gap.gap > 1
                            ) 
                        then
                            dateadd(day,-1,dateadd(year,1,gap.date_start))
                        else
                            gap.date_end
                    end,
                    case 
                        when gap.gap is null then 0 --new
                        when gap.gap > 1 then 1 --lapsed/reactivated
                    else
                        2 --active
                    end
                from
                    (
                        select
                            range_id,
                            date_start,
                            date_end,
                            datediff(day,lag(date_end) over (partition by range_id order by date_start),date_start) gap
                        from
                            add_end
                ) gap
            )
        , add_scg (range_id, _status, scg_id, date_start, date_end) as
            (
                select
                    s.range_id,
                    s._status,
                    s.scg_id,
                    min(s._date) date_start,
                    max(s._date) date_end
                from
                    (
                        select
                            r.range_id,
                            r._date,
                            r._status,
                            sum(r.is_changed) over (partition by r.range_id order by r._date) scg_id --status change group id
                        from
                            (
                                select
                                    q.range_id,
                                    q._date,
                                    q._status,
                                    case when
                                        (
                                            q._status = lag(q._status) over (partition by q.range_id order by q._date)
                                        )
                                    then
                                        0
                                    else
                                        1
                                    end is_changed
                                from
                                    (
                                        select
                                            add_status.range_id,
                                            iteration._date,
                                            min(add_status._status) _status
                                        from
                                            add_status
                                        cross apply
                                            (
                                                select
                                                    dateadd(day,it.iteration,add_status.date_start) _date
                                                from
                                                    db_sys.iteration it
                                                where
                                                    datediff(day,add_status.date_start,add_status.date_end) >= it.iteration
                                            ) iteration
                                        group by
                                            add_status.range_id,
                                            iteration._date
                                    ) q
                            ) r
                    ) s
                group by
                    s.range_id,
                    s._status,
                    s.scg_id
                having
                    max(s._date) >= datefromparts(year(getutcdate())-2,1,1)
            )
        
        select
            @customer_id customer_id,
            range_id,
            _status,
            row_number() over (partition by range_id order by date_start) scg_id,
            date_start,
            date_end
        from
            (
                select
                    range_id,
                    _status,
                    date_start,
                    date_end
                from
                    add_scg
                where
                    _status > 1

                union all

                select
                    l.range_id,
                    l._status,
                    l.date_start,
                    l.date_end
                from
                    add_status l
                where
                    (
                        l._status < 2
                    and l.date_end >= datefromparts(year(getutcdate())-2,1,1)
                    )
            ) u

    )