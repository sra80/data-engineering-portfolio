
CREATE view [forecast_feed].[sales_vw]

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
        sales.key_date >= datepart(year,dateadd(week,-2,getutcdate())) * 100 + datepart(week,dateadd(week,-2,getutcdate()))
    and sales.key_item in (select key_item from forecast_feed.item)
    and sales.key_customer in (select key_cus from forecast_feed.customer)
    )
GO
