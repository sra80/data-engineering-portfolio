CREATE view [marketing].[CSH_Static_Window]

as

with cus_status as
    (
        select h.No_, h.[Start Date], isnull(dateadd(day,-1,lead(h.[Start Date]) over (partition by h.No_ order by h.[Start Date])),getutcdate()) [End Date], h.[Status], [Last Order], (select min(order_range_start) from (values(h.[Start Date]),(h.[Last Order])) as value(order_range_start)) order_range_start from ext.CSH_Static_Window h where h.DeletedTSUTC is null
    )
, sales as
    (
        select 
            convert(date,h.[Order Date]) order_date,
            h.[Sell-to Customer No_] cus,
            l.No_ sku
        from
            ext.Sales_Header h
        join
            ext.Sales_Line l
        on
            (
                h.No_ = l.[Document No_]
            and h.[Document Type] = l.[Document Type]
            )
        where
            (
                h.[Sales Order Status] = 1
            )

        union all

        select
            convert(date,h.[Order Date]) order_date,
            h.[Sell-to Customer No_] cus,
            l.No_ sku
        from
            ext.Sales_Header_Archive h
        join
            ext.Sales_Line_Archive l
        on
            (
                h.No_ = l.[Document No_]
            and h.[Document Type] = l.[Document Type]
            and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
            and h.[Version No_] = l.[Version No_]
            )
        where
            h.[Order Date] >= datefromparts(year(getdate())-2,1,1)
    )

select 
    cus_status.[Start Date] csh_start,
    cus_status.[End Date] csh_end,
    sales.order_date,
    cus_status.[Status] csh_status,
    cus_status.No_ cus,
    sales.channel_code,
    isnull(sales.sku,'out_of_range') sku
from
    cus_status
outer apply
    marketing.fn_SalesOrders(No_,order_range_start,[End Date]) sales
where
    cus_status.[Status] < 4

union all

select 
    cus_status.[Start Date] csh_start,
    cus_status.[End Date] csh_end,
    cus_status.[Last Order] order_date,
    cus_status.[Status] csh_status,
    cus_status.No_ cus,
    null,
    'out_of_range' sku
from
    cus_status
where
    cus_status.[Status] >= 4
GO
