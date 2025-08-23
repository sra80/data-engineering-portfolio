CREATE view [price_tool_feed].[vw_stores]

as

select
    s.store_id,
    concat(case when z.zone_name = s.store_name then '' else concat(z.zone_name,' - ') end,s.store_name) [name]
from
    price_tool_feed.stores s
join
    price_tool_feed.zones z
on
    (
        s.zone_id = z.zone_id
    )
GO
