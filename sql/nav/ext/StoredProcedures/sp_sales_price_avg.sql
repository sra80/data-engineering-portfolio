create or alter procedure ext.sp_sales_price_avg

as

set nocount on

declare @row_count int, @item_id int, @single_sale money, @repeat_sale money

select
    @row_count = sum(1)
from
    ext.Item i
where
(
    datediff(month,i.lastOrder,getutcdate()) <= 6
and
    (
        i.avg_price_update is null
    or  dateadd(month,1,i.avg_price_update) < getutcdate()
    )
)

while @row_count > 0

begin

    select top 1
        @item_id = ID
    from
        ext.Item i
    where
        (
            datediff(month,i.lastOrder,getutcdate()) <= 6
        and
            (
                i.avg_price_update is null
            or  dateadd(month,1,i.avg_price_update) < getutcdate()
            )
        )

    select
        @single_sale = single_sale,
        @repeat_sale = repeat_sale
    from
        (
            select
                single_sale.unit_price single_sale,
                repeat_sale.unit_price repeat_sale
            from
                (
                    select
                        round(avg(x.unit_price),2) unit_price
                    from
                        (
                            select
                                unit_price,
                                percentile_cont(0.25) within group (order by unit_price) over() quartile_first,
                                percentile_cont(0.75) within group (order by unit_price) over() quartile_last
                            from
                                (
                                    select
                                        db_sys.fn_divide(l.[Amount Including VAT],l.Quantity,0) unit_price
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
                                    join
                                        ext.Item i
                                    on
                                        (
                                            l.company_id = i.company_id
                                        and l.No_ = i.No_
                                        )
                                    join
                                        ext.Channel c
                                    on
                                        (
                                            h.[Channel Code] = c.Channel_Code
                                        )
                                    where
                                        (
                                            h.[Sales Order Status] = 1
                                        and h.[Order Date] <= convert(date,sysdatetime())
                                        and h.[Order Date] >= dateadd(month,-6,sysdatetime())
                                        and i.ID = @item_id
                                        and c.is_visible_oos_plr = 1
                                        and c.Group_Code in (2,3)
                                        )

                                    union all

                                    select
                                        db_sys.fn_divide(l.[Amount Including VAT],l.Quantity,0) up
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
                                    join
                                        ext.Item i
                                    on
                                        (
                                            l.company_id = i.company_id
                                        and l.No_ = i.No_
                                        )
                                    join
                                        ext.Channel c
                                    on
                                        (
                                            h.[Channel Code] = c.Channel_Code
                                        )
                                    where
                                        (
                                            h.[Order Date] <= convert(date,sysdatetime())
                                        and h.[Order Date] >= dateadd(month,-6,sysdatetime())
                                        and i.ID = @item_id
                                        and c.is_visible_oos_plr = 1
                                        and c.Group_Code in (2,3)
                                        )
                                ) so
                        ) x
                        where
                            (
                                x.unit_price >= x.quartile_first
                            and x.unit_price <= x.quartile_last
                            )
                    ) single_sale
                cross apply
                    (
                    select
                        round(avg(x.unit_price),2) unit_price
                    from
                        (
                            select
                                unit_price,
                                percentile_cont(0.25) within group (order by unit_price) over() quartile_first,
                                percentile_cont(0.75) within group (order by unit_price) over() quartile_last
                            from
                                (
                                    select
                                        db_sys.fn_divide(l.[Amount Including VAT],l.Quantity,0) unit_price
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
                                    join
                                        ext.Item i
                                    on
                                        (
                                            l.company_id = i.company_id
                                        and l.No_ = i.No_
                                        )
                                    join
                                        ext.Channel c
                                    on
                                        (
                                            h.[Channel Code] = c.Channel_Code
                                        )
                                    where
                                        (
                                            h.[Sales Order Status] = 1
                                        and h.[Order Date] <= convert(date,sysdatetime())
                                        and h.[Order Date] >= dateadd(month,-6,sysdatetime())
                                        and i.ID = @item_id
                                        and c.is_visible_oos_plr = 1
                                        and c.Group_Code = 4
                                        )

                                    union all

                                    select
                                        db_sys.fn_divide(l.[Amount Including VAT],l.Quantity,0) up
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
                                    join
                                        ext.Item i
                                    on
                                        (
                                            l.company_id = i.company_id
                                        and l.No_ = i.No_
                                        )
                                    join
                                        ext.Channel c
                                    on
                                        (
                                            h.[Channel Code] = c.Channel_Code
                                        )
                                    where
                                        (
                                            h.[Order Date] <= convert(date,sysdatetime())
                                        and h.[Order Date] >= dateadd(month,-6,sysdatetime())
                                        and i.ID = @item_id
                                        and c.is_visible_oos_plr = 1
                                        and c.Group_Code = 4
                                        )
                                ) so
                        ) x
                        where
                            (
                                x.unit_price >= x.quartile_first
                            and x.unit_price <= x.quartile_last
                            )
                    ) repeat_sale
        ) spa

    update 
        ext.Item
    set
        avg_price_single = @single_sale,
        avg_price_repeat = @repeat_sale,
        avg_price_update = sysdatetime()
    where
        ID = @item_id

    set @row_count -= 1

end