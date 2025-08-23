CREATE function [marketing].[fn_SalesOrders]
    (
        @cus nvarchar(32),
        @start date,
        @end date
    )

returns table

as

return
select
    x.order_date,
    x.sku,
    x.channel_code,
    (select min(first_order) first_order_cus from ext.Customer_Item_Summary x where x.cus = @cus) first_order_cus,
    (
        select
            min(cis1.first_order) first_order_range
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
            (
                i0.[Range Code] = i1.[Range Code]
            )
        join
            ext.Customer_Item_Summary cis1
        on
            (
                cis0.cus = cis1.cus
            and i1.No_ = cis1.sku
            )
        where
            cis0.cus = @cus
        and cis0.sku = x.sku
    ) first_order_range
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
            h.No_ = l.[Document No_]
        and h.[Document Type] = l.[Document Type]
        )
    where
        (
            h.[Sales Order Status] = 1
        and h.[Sell-to Customer No_] = @cus
        and h.[Order Date] >= @start
        and h.[Order Date] <= isnull(@end,convert(date,getutcdate()))
        )

    union

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
            h.No_ = l.[Document No_]
        and h.[Document Type] = l.[Document Type]
        and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
        and h.[Version No_] = l.[Version No_]
        )
    where
        (
            h.[Sell-to Customer No_] = @cus
        and h.[Order Date] >= @start
        and h.[Order Date] <= isnull(@end,convert(date,getutcdate()))
        )
    ) x
where
    (   
        len(x.sku) > 0
    )
GO
