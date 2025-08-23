CREATE function [ext].[fn_CSH_Static_Window]
    (
		@cus nvarchar(20) 
    )

returns table

as

return
select
    event_date,
    customer_status,
    last_order
from
    (
    select
        event_date,
        customer_status,
        max(last_order) over (partition by change_instance) last_order,
        status_change,
        change_instance,
        case when max(change_instance) over() = change_instance then 1 else 0 end last_status
    from
        (
        select
            case realign_date when 1 then db_sys.static_year(lag(event_date) over (order by event_date),2) else event_date end event_date,
            customer_status,
            last_order,
            status_change,
            sum(status_change) over (order by event_date rows between unbounded preceding and current row) change_instance
        from
            (
            select
                event_date,
                customer_status,
                case when lag(customer_status) over (order by event_date) = customer_status then 0 else 1 end status_change,
                realign_date,
                max(last_order) over (order by event_date) last_order
            from
                (
                select
                    u.event_date,
                    case event_type
                        when 'order_date' then
                            case 
                                when db_sys.static_year(first_order,2) > event_date then 1 -- changed >= to > e.g. for fix: THO190K
                                when db_sys.static_year(isnull(last_react,first_order),2) <= event_date then 2
                                when db_sys.static_year(last_react,2) >= event_date then 3 
                            end
                        when 'next_act' then 2
                        when 'lapse_date' then 4
                        when 'gone_date' then 5
                    end customer_status,
                    case when event_type = 'order_date' and db_sys.static_year(isnull(last_react,first_order),2) <= event_date then 1 else 0 end realign_date,
                    last_order
                from
                    (
                select
                    order_date,
                    order_date last_order,
                    lapse_date,
                    gone_date,
                    first_order,
                    last_react,
                    case when order_count > 0 then next_act else null end next_act
                from
                    (
                    select
                        order_date,
                        lapse_date,
                        gone_date,
                        min(order_date) over () first_order,
                        case when lapse_date is not null then lag(last_react) over (order by order_date) else last_react end last_react,
                        next_act,
                        (
                            select 
                                isnull(sum(1),0) 
                            from 
                            (
                                select
                                    1 c
                                from
                                    [UK$Sales Header Archive]
                                where
                                    [Archive Reason] = 3
                                and [Sell-to Customer No_] = @cus
                                and [Order Date] >= dateadd(year,-1,next_act)
                                and [Order Date] <= dateadd(day,-1,next_act)

                                union

                                select
                                    1 c
                                from
                                    ext.Sales_Header
                                where
                                    company_id = 1
                                and [Sell-to Customer No_] = @cus
                                and [Sales Order Status] = 1
                                and [Order Date] >= dateadd(year,-1,next_act)
                                and [Order Date] <= dateadd(day,-1,next_act)
                            ) x
                        ) order_count --in window priot to next_act  e.g. HAN582H
                    from
                        (
                        select
                            order_date,
                            -- datediff(day,lag(order_date) over (order by order_date),order_date) d,
                            lapse_date,
                            gone_date,
                            case when db_sys.static_year(order_date,2) >= lead(order_date) over (order by order_date) and (lead(lapse_date) over (order by order_date) is null or lead(lapse_date) over (order by order_date) > db_sys.static_year(order_date,2)) then db_sys.static_year(order_date,2) else null end next_act /* e.h. C0385052 where status clash as result of leap year*/,
                            max(next_react) over (order by order_date rows between unbounded preceding and current row) last_react
                        from
                            (
                            select
                                order_date,
                                lapse_date,
                                gone_date,
                                case when lapse_date is not null then lead(order_date) over (order by order_date) end next_react
                            from
                                (
                                select
                                    b.order_date,
                                    case when db_sys.static_year(b.order_date,2) < isnull(lead(b.order_date) over (order by b.order_date),convert(date,getutcdate())) then db_sys.static_year(b.order_date,2) end lapse_date,
                                    case when db_sys.static_year(b.order_date,3) < isnull(lead(b.order_date) over (order by b.order_date),convert(date,getutcdate())) then db_sys.static_year(b.order_date,3) end gone_date
                                from
                                    (
                                    select
                                        a.order_date
                                    from
                                        (
                                        select
                                            order_date
                                        from
                                            scv.sales
                                        where
                                            (
                                                cus = @cus
                                            )
                            
                                        union

                                        select
                                            convert(date,[Order Date]) order_date
                                        from
                                            [UK$Sales Header Archive]
                                        where
                                            [Archive Reason] = 3
                                        and [Sell-to Customer No_] = @cus

                                        union

                                        select
                                            convert(date,[Order Date])
                                        from
                                            ext.Sales_Header
                                        where
                                            company_id = 1
                                        and [Sell-to Customer No_] = @cus
                                        and [Sales Order Status] = 1
                                        ) a
                                    ) b
                                ) c
                            ) d
                        ) e
                    ) f
                ) g
                unpivot
                (
                    event_date
                    for event_type in (order_date,lapse_date,gone_date,next_act)
                ) u
            ) h
        ) i
    ) j
) k
where
    (
        status_change = 1
    and 
        (
            last_order >= datefromparts(2017,1,1) -- changed from event_date to last_order
        or  last_status = 1
        )
    and event_date <= getutcdate()
    )
GO
