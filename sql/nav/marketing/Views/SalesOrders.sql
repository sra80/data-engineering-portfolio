create or alter view [marketing].[SalesOrders]

-- --M0 change by AJ on 220609
-- -- add edn_ID, optimize Amazon with link to finance.SalesInvoices_Amazon

as

select
	 0 model_partition
	,0 archive
	,0 return_receipt
	,0 aggregated_archive
	,0 affiliate_sale
    ,h.company_id
    ,h.[Created By ID] key_user
	,h.[Order Date] order_date
	,h.outcode_id
    ,ext.fn_Platform(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE'),h.No_,h.[Inbound Integration Code],default) ord_platformID
	,hs_identity.fn_Customer(h.company_id,h.[Sell-to Customer No_]) key_cus
	,ext.fn_Country_Region(h.company_id,h.[Ship-to Country_Region Code]) ord_dest_cou
	,ext.fn_Channel(h.company_id,h.[Channel Code]) key_channel
	-- ,ext.fn_Channel(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE')) channel_code
	,ext.fn_Media_Code(h.company_id,h.[Media Code]) media_code
	,ext.fn_Payment_MethodID(h.company_id,h.[Payment Method Code],null) payment_method
	,h.customer_status
	,0 cost_center_code
    -- ,ext.fn_cost_center_code(l.[Dimension Set ID],h.[Ship-to Country_Region Code]) cost_center_code
	,(select ID from ext.Location loc where h.company_id = loc.company_id and loc.location_code = l.[Location Code]) location_code
	,i.ID key_sku
	,/*l.Quantity*ext.fn_Forecast_Ratio(h.[Order Date],l.[Location Code],l.No_)*/ 0 qty_forcast
    ,(select ID from ext.External_Document_Number edn where h.company_id = edn.company_id and h.[External Document No_] = edn.[External Document No_]) edn_ID
	,NULL return_reason --MO
	--,l.ord_count
	,l.Quantity qty
    ,l.[Promotion Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_dis_promo
	,l.[Line Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_dis_ttl
	,l.[Amount Including VAT]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_gros
	,l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_net
	,l.Quantity * ext.fn_sales_price_GBP(h.company_id,l.No_,h.[Order Date],'FULLPRICES') price_fullprice
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
		i.company_id = l.company_id 
	and i.No_ = l.No_
	)
where
    (
        h.[Sales Order Status] = 1
	and h.[Order Date] <= convert(date,sysdatetime())
    )


union all

select
     100 + p._partition model_partition
	,1 archive
	,0 return_receipt
	,0 aggregated_archive
	,0 affiliate_sale
	,h.company_id
    ,h.[Created By ID] key_user
	,h.[Order Date] order_date
	,h.outcode_id
    ,ext.fn_Platform(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE'),h.No_,h.[Inbound Integration Code],default) ord_platformID
	,hs_identity.fn_Customer(h.company_id,h.[Sell-to Customer No_]) key_cus
	,ext.fn_Country_Region(h.company_id,h.[Ship-to Country_Region Code]) ord_dest_cou
	,ext.fn_Channel(h.company_id,h.[Channel Code]) key_channel
	-- ,ext.fn_Channel(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE')) channel_code
	,ext.fn_Media_Code(h.company_id,h.[Media Code]) media_code
	,ext.fn_Payment_MethodID(h.company_id,h.[Payment Method Code],null) payment_method
    ,h.customer_status
	,0 cost_center_code
    -- ,l.cost_center_code
	,(select ID from ext.Location loc where h.company_id = loc.company_id and loc.location_code = l.[Location Code]) location_code
	,i.ID key_sku
	,0 qty_forcast
    ,(select ID from ext.External_Document_Number edn where h.company_id = edn.company_id and h.[External Document No_] = edn.[External Document No_]) edn_ID
	,NULL return_reason --MO
    --,l.ord_count
	,l.Quantity qty
    ,l.[Promotion Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_dis_promo
	,l.[Line Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_dis_ttl
	,l.[Amount Including VAT]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_gros
	,l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_net
	,l.Quantity * ext.fn_sales_price_GBP(h.company_id,l.No_,h.[Order Date],'FULLPRICES') price_fullprice
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
		i.company_id = l.company_id 
	and i.No_ = l.No_
	)
join
    db_sys.model_partition_month p
on
    (
        year(h.[Order Date]) = p._year
    and month(h.[Order Date]) = p._month
    )
 where
 	(
         h.[Order Date] >= datefromparts(year(getutcdate())-2,1,1)
     )

union all

select
	 2 model_partition
	,0 archive
	,1 return_receipt
	,0 aggregated_archive
	,0 affiliate_sale
	,h.company_id
    ,null key_user
	,convert(date,h.[Posting Date]) order_date
	,null outcode_id
    ,0 ord_platformID
	,hs_identity.fn_Customer(h.company_id,h.[Sell-to Customer No_]) key_cus
	,ext.fn_Country_Region(h.company_id,h.[Ship-to Country_Region Code]) ord_dest_cou
	,ext.fn_Channel(h.company_id,h.[Channel Code]) key_channel
	-- ,ext.fn_Channel(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE')) channel_code
	,ext.fn_Media_Code(h.company_id,h.[Media Code]) media_code
	,null payment_method
	,null customer_status
	,0 cost_center_code
    -- ,ext.fn_cost_center_code(l.[Dimension Set ID],h.[Ship-to Country_Region Code]) cost_center_code
	,(select ID from ext.Location loc where h.company_id = loc.company_id and loc.location_code = l.[Location Code]) location_code
	,i.ID key_sku
	,0 qty_forcast
    ,(select ID from ext.External_Document_Number edn where h.company_id = edn.company_id and isnull(nullif(h.[External Document No_],''),h.No_) = edn.[External Document No_]) edn_ID
	,(select ID from ext.Return_Reason rr where rr.company_id = h.company_id and rr.code = l.[Return Reason Code]) return_reason --MO
    --,case when row_number() over (partition by h.No_ order by h.No_) = 1 then 1 else 0 end ord_count
	,-l.Quantity qty
    ,ext.fn_Convert_Currency_GBP((-l.[Promotion Discount _]/100)/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,h.[company_id],h.[Posting Date]) amt_dis_promo
	,ext.fn_Convert_Currency_GBP(-l.[Line Discount _]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,h.[company_id],h.[Posting Date]) amt_dis_ttl
	,ext.fn_Convert_Currency_GBP(-l.[Item Charge Base Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,h.[company_id],h.[Posting Date]) amt_gros
	,ext.fn_Convert_Currency_GBP(-l.[VAT Base Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,h.[company_id],h.[Posting Date]) amt_net
	,-l.Quantity * ext.fn_sales_price_GBP(h.company_id,l.No_,h.[Order Date],'FULLPRICES') price_fullprice
from
	[hs_consolidated].[Return Receipt Header] h
join
	[hs_consolidated].[Return Receipt Line] l
on
	(
		h.company_id = l.company_id
	and h.No_ = l.[Document No_]
	)
join
	ext.Item i
on
	(
		i.company_id = l.company_id
	and i.No_ = l.No_
	)
where
	(
		h.[Posting Date] >= datefromparts(year(getdate())-2,1,1)
    )

union all

select
	 3 model_partition
	,0 archive
	,0 return_receipt
	,1 aggregated_archive
	,0 affiliate_sale
	,company_id
    ,null key_user
	,_date order_date
	,null outcode_id
    ,null ord_platformID
	,-cus_type-1 key_cus
	,country
	,channel
	-- ,channel
	,null media_code
	,null payment_method
    ,null customer_status
	,0 cost_center_code
    -- ,'D2C' cost_center_code
	,null location_code
	,sku key_sku
	,0 qty_forcast
    ,-1 edn_ID 
	,NULL return_reason --MO
	-- ,0 ord_count
	,quantity
	,vouchers
	,vouchers
	,gross_revenue
	,net_revenue
	,quantity * ext.fn_sales_price_GBP(company_id,sku,_date,'FULLPRICES') price_fullprice
from
	ext.Sales_Archive
where
	_date < datefromparts(year(getdate())-2,1,1)

union all

select
	 4 model_partition
	,0 archive
	,0 return_receipt
	,0 aggregated_archive
	,1 affiliate_sale
	,h.company_id
    ,h.[Created By ID] key_user
	,h.[Order Date] order_date
	,h.outcode_id
    ,ext.fn_Platform(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE'),h.No_,h.[Inbound Integration Code],default) ord_platformID
	,hs_identity.fn_Customer(h.company_id,m.[Customer No_]) key_cus
	,ext.fn_Country_Region(h.company_id,h.[Ship-to Country_Region Code]) ord_dest_cou
	,ext.fn_Channel(h.company_id,h.[Channel Code]) key_channel
	-- ,ext.fn_Channel(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE')) channel_code
	,ext.fn_Media_Code(h.company_id,h.[Media Code]) media_code
	,ext.fn_Payment_MethodID(h.company_id,h.[Payment Method Code],null) payment_method
	,null customer_status
	,0 cost_center_code
    -- ,ext.fn_cost_center_code(l.[Dimension Set ID],h.[Ship-to Country_Region Code]) cost_center_code
	,(select ID from ext.Location loc where h.company_id = loc.company_id and loc.location_code = l.[Location Code]) location_code
	,i.ID key_sku
	,0 qty_forcast
    ,(select ID from ext.External_Document_Number edn where h.company_id = edn.company_id and h.[External Document No_] = edn.[External Document No_]) edn_ID
	,NULL return_reason --MO
	-- ,l.ord_count
	,l.Quantity qty
    ,l.[Promotion Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_dis_promo
	,l.[Line Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_dis_ttl
	,l.[Amount Including VAT]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_gros
	,l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_net
	,l.Quantity * ext.fn_sales_price_GBP(h.company_id,l.No_,h.[Order Date],'FULLPRICES') price_fullprice
from
	ext.Sales_Header h
join
	ext.Sales_Line l
on
	(
		h.No_ = l.[Document No_]
	and h.[Document Type] = l.[Document Type]
	)
join
	ext.Item i
on
	(
		i.company_id = l.company_id
	and i.No_ = l.No_
	)
join
	hs_consolidated.[Media Code] m
on
	(
		h.company_id = m.company_id
	and h.[Media Code] = m.[Code]
	)
where
	(
		h.[Sell-to Customer No_] != nullif(m.[Customer No_],'')
	and h.[Sales Order Status] = 1
	)

union all

select
	 200 + p._partition model_partition
	,1 archive
	,0 return_receipt
	,0 aggregated_archive
	,1 affiliate_sale
	,h.company_id
    ,h.[Created By ID] key_user
	,h.[Order Date] order_date
	,h.outcode_id
    ,ext.fn_Platform(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE'),h.No_,h.[Inbound Integration Code],default) ord_platformID
	,hs_identity.fn_Customer(h.company_id,m.[Customer No_]) key_cus
	,ext.fn_Country_Region(h.company_id,h.[Ship-to Country_Region Code]) ord_dest_cou
	,ext.fn_Channel(h.company_id,h.[Channel Code]) key_channel
	-- ,ext.fn_Channel(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE')) channel_code
	,ext.fn_Media_Code(h.company_id,h.[Media Code]) media_code
	,ext.fn_Payment_MethodID(h.company_id,h.[Payment Method Code],null) payment_method
	,null customer_status
	,0 cost_center_code
    -- ,l.cost_center_code
	,(select ID from ext.Location loc where h.company_id = loc.company_id and loc.location_code = l.[Location Code]) location_code
	,i.ID key_sku
	,0 qty_forcast
    ,(select ID from ext.External_Document_Number edn where h.company_id = edn.company_id and h.[External Document No_] = edn.[External Document No_]) edn_ID
	,NULL return_reason --MO
    -- ,l.ord_count
	,l.Quantity qty
    ,l.[Promotion Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_dis_promo
	,l.[Line Discount Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_dis_ttl
	,l.[Amount Including VAT]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_gros
	,l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end amt_net
	,l.Quantity * ext.fn_sales_price_GBP(h.company_id,l.No_,h.[Order Date],'FULLPRICES') price_fullprice
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
join
	ext.Item i
on
	(
		i.company_id = l.company_id
	and i.No_ = l.No_
	)
join
	hs_consolidated.[Media Code] m
on
	(
		h.company_id = m.company_id
	and h.[Media Code] = m.[Code]
	)
cross apply
    db_sys.model_partition_bi p
where
    (
        h.[Order Date] >= datefromparts(year(getdate())-2,1,1)
    and h.[Order Date] >= p.date_start
    and h.[Order Date] <= p.date_end
    and h.[Sell-to Customer No_] != nullif(m.[Customer No_],'')
    )

union all

select
	 6 model_partition
	,0 archive
	,1 return_receipt
	,0 aggregated_archive
	,1 affiliate_sale
	,h.company_id
    ,null key_user
	,convert(date,h.[Posting Date]) order_date
	,null outcode_id
    ,0 ord_platformID
	,hs_identity.fn_Customer(h.company_id,m.[Customer No_]) key_cus
	,ext.fn_Country_Region(h.company_id,h.[Ship-to Country_Region Code]) ord_dest_cou
	,ext.fn_Channel(h.company_id,h.[Channel Code]) key_channel
	-- ,ext.fn_Channel(h.company_id,isnull(nullif(h.[Channel Code],''),'PHONE')) channel_code
	,ext.fn_Media_Code(h.company_id,h.[Media Code]) media_code
	,null payment_method
	,null customer_status
	,0 cost_center_code
    -- ,ext.fn_cost_center_code(l.[Dimension Set ID],h.[Ship-to Country_Region Code]) cost_center_code
	,(select ID from ext.Location loc where h.company_id = loc.company_id and loc.location_code = l.[Location Code]) location_code
	,i.ID key_sku
	,0 qty_forcast
    ,(select ID from ext.External_Document_Number edn where h.company_id = edn.company_id and isnull(nullif(h.[External Document No_],''),h.No_) = edn.[External Document No_]) edn_ID
	,(select ID from ext.Return_Reason rr where rr.company_id = h.company_id and rr.code = l.[Return Reason Code]) return_reason --MO
    -- ,case when row_number() over (partition by h.No_ order by h.No_) = 1 then 1 else 0 end ord_count
	,-l.Quantity qty	
    ,ext.fn_Convert_Currency_GBP((-l.[Promotion Discount _]/100)/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,h.[company_id],h.[Posting Date]) amt_dis_promo
	,ext.fn_Convert_Currency_GBP(-l.[Line Discount _]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,h.[company_id],h.[Posting Date]) amt_dis_ttl
	,ext.fn_Convert_Currency_GBP(-l.[Item Charge Base Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,h.[company_id],h.[Posting Date]) amt_gros
	,ext.fn_Convert_Currency_GBP(-l.[VAT Base Amount]/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,h.[company_id],h.[Posting Date]) amt_net
	,-l.Quantity * ext.fn_sales_price_GBP(h.company_id,l.No_,h.[Order Date],'FULLPRICES') price_fullprice
from
	[hs_consolidated].[Return Receipt Header] h
join
	[hs_consolidated].[Return Receipt Line] l
on
	(
		h.company_id = l.company_id
	and h.No_ = l.[Document No_]
	)
join
	ext.Item i
on
	(
		i.company_id = l.company_id
	and i.No_ = l.No_
	)
join
	hs_consolidated.[Media Code] m
on
	(
		h.company_id = m.company_id	
	and h.[Media Code] = m.[Code]
	)
where
	(
		h.[Posting Date] >= datefromparts(year(getdate())-2,1,1)
	and h.[Sell-to Customer No_] != nullif(m.[Customer No_],'')
    )

union all

select --changed 2022-06-16 12:24:36.973, added FBA EU and partitions 
	 300 + p._partition model_partition
	,0 archive
	,0 return_receipt
	,0 aggregated_archive
	,0 affiliate_sale 
	,1 company_id
    ,null key_user
	,convert(date,ile.[Document Date]) order_date --changed Posting Date to Document Date
	,null outcode_id
    ,amz.platformID ord_platformID
	,hs_identity.fn_Customer(1,amz.cus_code) key_cus
	,ext.fn_Country_Region(1,ile.[Country_Region Code]) ord_dest_cou
	,ext.fn_Channel(1,amz.channel_code) key_channel
	-- ,ext.fn_Channel(1,amz.channel_code) channel_code
	,ext.fn_Media_Code(1,amz.media_code) media_code
    ,ext.fn_Payment_MethodID(1,'X_3P',null) payment_method
	,null customer_status
	,0 cost_center_code
    -- ,ext.fn_cost_center_code(ile.[Dimension Set ID],ile.[Country_Region Code]) cost_center_code
	,(select ID from ext.Location loc where loc.company_id = 1 and loc.location_code = ile.[Location Code]) location_code
	,i.ID key_sku
	,0 qty_forecast
    ,(select ID from ext.External_Document_Number edn where edn.company_id = 1 and ile.[External Document No_] = edn.[External Document No_]) edn_ID
	,NULL return_reason --MO
	-- ,ve.ord_count
	,-ile.[Quantity] qty
	,ve.amt_dis_promo 
	,ve.amt_dis_promo amt_dis_ttl
	,ve.amt_gros
	,case 
		when ile.[Location Code] = 'AMAZON' and ile.[Country_Region Code] = 'GB' then ve.amt_gros/v.[VAT Rate]
		when patindex('GB',ile.[Country_Region Code]) = 0 then ve.amt_gros
	 end amt_net
	,-ile.Quantity * ext.fn_sales_price(ve.[Item No_],ile.[Document Date],'FULLPRICES') price_fullprice
from
	[dbo].[UK$Item Ledger Entry] ile 
join
    finance.SalesInvoices_Amazon amz
on
    (
        ile.[Location Code] = amz.warehouse
    )
join 
		(select 
			 [Item Ledger Entry No_]
			,[Item No_]
			,sum([Discount Amount]) amt_dis_promo
			,sum([Sales Amount (Actual)]) amt_gros
		from 
			[dbo].[UK$Value Entry] x
		group by 
			 [Item Ledger Entry No_]
			,[Item No_]
			) ve
on 
	ile.[Entry No_] = ve.[Item Ledger Entry No_]
join
	ext.Item i
on
	(
		i.company_id = 1
	and i.No_ = ve.[Item No_]
	)
left join
		  ( select
				 i.[No_]
				,d.[Ship-to Country_Region Code]
				,v.[VAT Bus_ Posting Group]
				,v.[VAT Prod_ Posting Group]
				,(v.[VAT _]/100)+1 [VAT Rate]
			from
				[dbo].[UK$Item] i 
			join
				[dbo].[UK$VAT Posting Setup] v
			on
				i.[VAT Prod_ Posting Group] = v.[VAT Prod_ Posting Group]
			join
				[dbo].[UK$Distance Sale VAT] d 
			on
				v.[VAT Bus_ Posting Group] = d.[VAT Bus_ Posting Group]	
			where
				d.[Location Code] = 'WASDSP'
			and d.[VAT Bus_ Posting Group] <> 'STD'
			) v 
on
	ile.[Item No_] = v.[No_]
and ile.[Country_Region Code] = v.[Ship-to Country_Region Code]
cross apply
    db_sys.model_partition_bi p
where
    (
			ile.[Document Date] >= p.date_start
		and ile.[Document Date] <= p.date_end
	and ile.[Entry Type] = 1
	and ile.[Document Type] = 0
	)

union all

select
	 8 model_partition
	,0 archive
	,0 return_receipt
	,0 aggregated_archive
	,0 affiliate_sale
	,1 company_id
    ,null key_user
	-- ,convert(date,_date) order_date
    ,convert(date,sysdatetime()) order_date
	,null outcode_id
    ,null ord_platformID
	,-(select ID-1 from ext.Customer_Type where company_id = 1 and nav_code = 'DIRECT') key_cus
	,ext.fn_Country_Region(1,N'GB') ord_dest_cou
	,null key_channel
	-- ,null channel_code
	,null media_code
    ,null payment_method
    ,null customer_status
	,0 cost_center_code
    -- ,'D2C' cost_center_code
	-- ,(select ID from ext.Location loc where loc.company_id = 1 and loc.location_code = Forecast.location_code) location_code
    , 0 location_code
	-- ,(select ID from ext.Item i where i.company_id = 1 and i.No_ = Forecast.sku)  key_sku
    ,0 key_sku
	-- ,forecast qty_forecast
    ,0 qty_forecast
    ,-1 edn_ID
	,null return_reason --MO
	-- ,0_count
	,0 qty
	,0 amt_dis_promo 
	,0 amt_dis_ttl
	,0 amt_gros
	,0 amt_net
	,0 price_fullprice
-- from
-- 	marketing.Forecast
GO
