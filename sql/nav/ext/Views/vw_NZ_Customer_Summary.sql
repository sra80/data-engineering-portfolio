create or alter view ext.vw_NZ_Customer_Summary

as

with customer_status as
    (
        select
            _month,
            [New],
            [Lapsed Reactivated]
        from
            (
                select
                    cs.[Customer_Status],
                    eomonth(x.date_start) _month
                from
                    (
                        select distinct
                            last_status.customer_id,
                            last_status.date_start
                        from
                            (
                                select
                                    customer_id,
                                    max(date_start) date_start
                                from
                                    ext.Customer_Status_History_v2
                                where
                                    date_start >= datefromparts(year(getutcdate()),1,1)
                                group by
                                    customer_id
                            ) last_status
                        join
                            hs_identity.Customer c
                        on
                            (
                                last_status.customer_id = c.customer_id
                            )
                        join
                            hs_identity_link.Customer_NAVID n
                        on
                            (
                                c.nav_id = n.ID
                            )
                        join
                            hs_consolidated.Customer cx
                        on
                            (
                                n.company_id = cx.company_id
                            and n.nav_code = cx.No_
                            )
                        where
                            (
                                n.company_id = 5
                            and cx.[Customer Type] = 'NZ_WEB'
                            )
                    ) x
                join
                    ext.Customer_Status_History_v2 csh
                on
                    (
                        x.customer_id = csh.customer_id
                    and x.date_start = csh.date_start
                    )
                join
                    ext.Customer_Status cs
                on
                    (
                        csh.status_id = cs.ID
                    )
            ) x
        pivot
            (
                count(x.Customer_Status)
            for
                [Customer_Status] in ([New],[Lapsed Reactivated])
            )
        p
    )
,active_customers as
    (
        select
            _month,
            count(distinct customer_id) active_customers
        from
            (
                select
                    eomonth(h.[Order Date]) _month,
                    h.customer_id
                from
                    ext.Sales_Header h
                join
                    hs_consolidated.Customer c
                on
                    (
                        h.company_id = c.company_id
                    and h.[Sell-to Customer No_] = c.No_
                    )
                where
                    (
                        h.company_id = 5
                    and h.[Order Date] >= datefromparts(year(getutcdate()),1,1)
                    and c.[Customer Type] = 'NZ_WEB'
                    )

                union

                select
                    eomonth(h.[Order Date]) _month,
                    h.customer_id
                from
                    ext.Sales_Header_Archive h
                join
                    hs_consolidated.Customer c
                on
                    (
                        h.company_id = c.company_id
                    and h.[Sell-to Customer No_] = c.No_
                    )
                where
                    (
                        h.company_id = 5
                    and h.[Order Date] >= datefromparts(year(getutcdate()),1,1)
                    and c.[Customer Type] = 'NZ_WEB'
                    )
            ) x
        group by
            x._month
    )
, revenue as
    (
        select
            eomonth(order_date) _month,
            sum(case when r = 1 then amt_net end) first_order,
            sum(case when r > 1 then amt_net end) subsequent_orders
        from
            (
                select
                    order_date,
                    amt_net,
                    row_number() over (partition by customer_id order by order_date) r
                from
                    (
                        select
                            h.[Order Date] order_date,
                            csh.customer_id,
                            l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_net
                        from
                            ext.Customer_Status_History_v2 csh
                        join
                            hs_identity_link.Customer c
                        on
                            (
                                csh.customer_id = c.ID
                            )
                        join
                            hs_identity_link.Customer_NAVID n
                        on
                            (
                                c.nav_id_base = n.ID
                            )
                        join
                            hs_consolidated.Customer d
                        on
                            (
                                n.company_id = d.company_id
                            and n.nav_code = d.No_
                            )
                        join
                            ext.Sales_Header h
                        on
                            (
                                d.company_id = h.company_id
                            and d.[No_] = h.[Sell-to Customer No_]
                            )
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
                                year(csh.date_start) = year(getutcdate())
                            and csh.status_id = 1
                            and d.[Customer Type] = 'NZ_WEB'
                            and h.company_id = 5
                            and h.[Sales Order Status] = 1
                            and h.[Order Date] <= convert(date,sysdatetime())
                            )

                        union all

                        select
                            h.[Order Date] order_date,
                            csh.customer_id,
                            l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_net
                        from
                            ext.Customer_Status_History_v2 csh
                        join
                            hs_identity_link.Customer c
                        on
                            (
                                csh.customer_id = c.ID
                            )
                        join
                            hs_identity_link.Customer_NAVID n
                        on
                            (
                                c.nav_id_base = n.ID
                            )
                        join
                            hs_consolidated.Customer d
                        on
                            (
                                n.company_id = d.company_id
                            and n.nav_code = d.No_
                            )
                        join
                            ext.Sales_Header_Archive h
                        on
                            (
                                d.company_id = h.company_id
                            and d.[No_] = h.[Sell-to Customer No_]
                            )
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
                                year(csh.date_start) = year(getutcdate())
                            and csh.status_id = 1
                            and d.[Customer Type] = 'NZ_WEB'
                            and h.company_id = 5
                            and h.[Order Date] <= convert(date,sysdatetime())
                            )
                    ) x
            ) y
        group by
            eomonth(order_date)
    )

select
    format(cs._month,'MMMM yyyy') [Month],
    cs.[New],
    cs.[Lapsed Reactivated],
    ac.active_customers [Overall Active Customers],
    format(round(rv.first_order,2),'###,##0.00') [New First Order £],
    format(round(rv.subsequent_orders,2),'###,##0.00') [New Subsequent Orders £],
    format(round(rv.first_order,2) + round(rv.subsequent_orders,2),'###,##0.00') [New Total £],
    row_number() over (order by cs._month) r
from
    customer_status cs
join
    active_customers ac
on
    (
        cs._month = ac._month
    )
join
    revenue rv
on
    (
        cs._month = rv._month
    )