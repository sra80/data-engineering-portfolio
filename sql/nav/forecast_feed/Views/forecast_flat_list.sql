
CREATE view [forecast_feed].[forecast_flat_list]

as

select
	 concat([key_demand_channel],'_',[key_customer],'_',[key_sales_channel],'_',[key_location],'_',[key_item]) [primary_key]
	,[key_location]
	,[key_demand_channel]
	,[key_sales_channel]
    ,[key_customer]
    ,[key_item]
from
	(
		select distinct 
			 [key_location]
			,[key_demand_channel]
			,[key_sales_channel]
			,[key_customer]
			,[key_item]
		from
			[forecast_feed].[sales]
	) x
where
    (
        x.key_item in (select key_item from forecast_feed.item)
    )
GO
