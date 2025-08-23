

create   procedure [ext].[sp_Sales_Archive_Aggregated]

as

set nocount on

declare @s table (company_id int, _date date, cus_type int, country int, channel int, sku int, quantity int, vouchers money, gross_revenue money, net_revenue money)

insert into @s (company_id, _date, cus_type, country, channel, sku, quantity, vouchers, gross_revenue, net_revenue)
select
	sales.company_id,
	sales._date,
	sales.cus_type,
	sales.country,
	sales.channel,
	sales.sku,
	sum(quantity),
	sum(vouchers),
	sum(gross_revenue),
	sum(net_revenue)
from
	(	
		select 
			h.company_id,
			dateadd(week,datediff(week,i.firstOrder,h.[Order Date]),i.firstOrder) _date,
			ct.ID cus_type,
			(select ID from ext.Country_Region cr where cr.company_id = h.company_id and cr.country_code = h.[Ship-to Country_Region Code]) country,
			(select ID from ext.Channel ch where ch.company_id = h.company_id and ch.Channel_Code = replace(h.[Channel Code],'TELE','PHONE')) channel,
			i.ID sku,
			l.Quantity quantity,
			l.[Promotion Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end vouchers,
			l.[Amount Including VAT]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end gross_revenue,
			l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end net_revenue
		from
			ext.Item i
		join
			ext.Sales_Line_Archive l
		on
			(
				i.company_id = l.company_id
			and i.No_ = l.No_
			)
		join
			ext.Sales_Header_Archive h
		on
			(
				l.company_id = h.company_id
			and h.No_ = l.[Document No_]
			and h.[Document Type] = l.[Document Type]
			and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
			and h.[Version No_] = l.[Version No_]
			)
		join
			hs_consolidated.Customer c
		on
			(
				h.company_id = c.company_id
			and h.[Sell-to Customer No_] = c.No_
			)
		join
			ext.Customer_Type ct
		on
			(
				c.company_id = ct.company_id
			and c.[Customer Type] = ct.nav_code
			)
		where
			(
				datediff(week,dateadd(week,datediff(week,i.firstOrder,h.[Order Date]),i.firstOrder),getdate()) <= 6
			)
	 ) sales
group by
    sales.company_id,
	sales._date,
	sales.cus_type,
	sales.country,
	sales.channel,
	sales.sku

delete from ext.Sales_Archive where exists (select 1 from @s s where Sales_Archive.company_id = s.company_id and Sales_Archive._date = s._date and Sales_Archive.cus_type = s.cus_type and Sales_Archive.country = s.country and Sales_Archive.channel = s.channel and Sales_Archive.sku = s.sku)

insert into ext.Sales_Archive (company_id, _date, cus_type, country, channel, sku, quantity, vouchers, gross_revenue, net_revenue)
select company_id, _date, cus_type, country, channel, sku, quantity, vouchers, gross_revenue, net_revenue from @s
GO
