
create procedure stock.sp_forecast_ratio
    (
        @year int = null
    )

as

if @year is null set @year = year(getutcdate())-1

delete from stock.forecast_ratio where base_year = @year

insert into stock.forecast_ratio (base_year, dow, dow_ratio)
select
    base_year,
    dow,
    db_sys.fn_divide(q,sum(q) over (),0) dow_ratio
from
    (
        select
            base_year,
            dow,
            sum(Quantity) q
        from
            (
                select
                    datepart(year,h.[Order Date]) base_year,
                    datepart(dw,h.[Order Date]) dow,
                    l.Quantity
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
                        h.[Sales Order Status] = 1
                    and h.[Order Date] >= datefromparts(@year,1,1)
                    and h.[Order Date] < datefromparts(@year+1,1,1)
                    )

                union all

                select
                    datepart(year,h.[Order Date]) base_year,
                    datepart(dw,h.[Order Date]),
                    l.Quantity
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
                        h.[Order Date] >= datefromparts(@year,1,1)
                    and h.[Order Date] < datefromparts(@year+1,1,1)
                    )
            ) s
        group by
            base_year,
            dow
    ) t
GO
