CREATE function ext.fn_Customer_Item_Summary
    (
        @cus nvarchar(32), 
        @sku nvarchar(32) = null
    )

returns table

as

return
select
    cus,
    sku,
    isnull(sum(floor(qty)),0) units,
    convert(money,round(isnull(sum(amt_gros),0),4)) gross,
    convert(money,round(isnull(sum(amt_net),0),4)) net,
    min(order_date) first_order,
    max(order_date) last_order
from
    (
    select 
        h.[Sell-to Customer No_] cus,
        l.No_ sku,
        l.Quantity qty,
        l.[Amount Including VAT]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_gros,
	    l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_net,
        convert(date,h.[Order Date]) order_date
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

    union 

    select
        h.[Sell-to Customer No_],
        l.No_,
        l.Quantity,
        l.[Amount Including VAT]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_gros,
	    l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_net,
        convert(date,h.[Order Date]) 
    from
        dbo.Sales_Header_Archive h
    join
        dbo.Sales_Line_Archive l
    on
        (
            h.No_ = l.[Document No_]
        and h.[Document Type] = l.[Document Type]
        and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
        and h.[Version No_] = l.[Version No_]
        )
    where
        (
            h.[Archive Reason] = 3
        )

    union 

    select
        cus,
        sku,
        qty,
        gross,
        net,
        order_date
    from
        scv.sales
    ) x
where
    (
        x.cus = @cus
    and x.sku = isnull(@sku,x.sku)
    and len(x.cus) > 0
    and len(x.sku) > 0
    )
group by
    cus,
    sku
GO
