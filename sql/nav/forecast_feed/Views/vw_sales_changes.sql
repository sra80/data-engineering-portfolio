create or alter view forecast_feed.vw_sales_changes

as

select
    key_date,
    key_demand_channel,
    key_customer,
    key_sales_channel,
    key_location,
    key_item,
    units adjustment_qty
from 
    forecast_feed.sales_changes
where
    (
        abs(units) > 0
    )