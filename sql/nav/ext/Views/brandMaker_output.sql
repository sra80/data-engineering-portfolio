
create   view [ext].[brandMaker_output] as 

select 
	 item_sku
	,item_description
	,item_country_of_origin
	,item_range_description
	,item_range_code
	,item_status
	,FSAI
	,item_pack_size
	,item_gross_weight
	,item_ean
	,item_channels
	,item_format
	,item_width
	,item_height
	,item_length
	,item_weight_net
	--,item_weight_gross
	,item_dietary_attributes
	,item_default_price
	,item_subscribe_saving
	,commodity_code
from 
	ext.vw_brandMaker_sync s
where
	exists (select 1 from ext.Item i where i.company_id = 1 and s.item_sku = i.No_ and i.outstandingBMSync = 1)
GO
