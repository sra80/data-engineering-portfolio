create view price_tool_feed.vw_cross_check

as

select
    [month],
    category_id,
    store_id,
    total_quantity,
    total_revenue,
    total_profit
from
    price_tool_feed.cross_check
GO
