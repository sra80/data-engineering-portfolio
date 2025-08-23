create or alter function ext.fn_sales
    (
        @id int
    )

returns table as

return

select
    sum(l.[Promotion Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end) amt_dis_promo,
	sum(l.[Line Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end) amt_dis_ttl,
	sum(l.[Amount Including VAT]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end) amt_gros,
	sum(l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end) amt_net,
	sum(l.Quantity * ext.fn_sales_price_GBP(h.company_id,l.No_,h.[Order Date],'FULLPRICES')) price_fullprice
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
        h.id = @id
    )