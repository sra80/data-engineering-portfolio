
create or alter view [forecast_feed].[subscription_forecast]

as

select
	 row_number() over(order by key_date, s.item_id) primary_key,
     s.row_version,
	 s.key_date, 
    --  (select top 1 ID from ext.Platform where Platform = 'Subscriptions' and Country = (select top 1 Country from db_sys.Company where ID = ei.company_id)) key_demand_channel,
    ext.fn_Platform_Grouping(ei.company_id,'REPEAT','SO-123456','NAV',0) key_demand_channel,
	--  (select top 1 key_cus from forecast_feed.customer where customer_name = 'Direct to Consumer' and customer_type = 'Direct') key_customer,
    -1000 key_customer,
	 'D2C' key_sales_channel,
	--  (select top 1 ID from ext.Location where company_id = ei.company_id and location_code = (select [Pick Location] from hs_consolidated.Item t where t.company_id = ei.company_id and t.No_ = ei.[No_])) key_location,
	s.location_id key_location,
     s.item_id key_item,
     s.units
from
	(select row_version, datepart(year,ndd)*100 + datepart(week,ndd) key_date, location_id, item_id, sum(quantity) units from stock.forecast_subscriptions where datepart(year,ndd)*100 + datepart(week,ndd) >= datepart(year,getutcdate())*100 + datepart(week,getutcdate()) and row_version = (select row_version from stock.forecast_subscriptions_version where is_current = 1) and is_original = 1 group by row_version, datepart(year,ndd)*100 + datepart(week,ndd), location_id, item_id) s
join
	ext.Item ei
on
	(
        s.item_id = ei.ID
	)
where
    ei.ID in (select key_item from forecast_feed.item)
GO
