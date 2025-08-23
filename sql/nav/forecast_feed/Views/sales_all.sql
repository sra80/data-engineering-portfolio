
CREATE view [forecast_feed].[sales_all]

as

select
	sales.primary_key,
    sales.key_date,
    sales.key_demand_channel,
    sales.key_customer,
    sales.key_sales_channel,
    sales.key_location,
    sales.key_item,
    sales.units
from
    forecast_feed.sales
where
    (
        sales.key_item in (select key_item from forecast_feed.item)
    and sales.key_customer in (select key_customer from forecast_feed.customer)
    )
GO
