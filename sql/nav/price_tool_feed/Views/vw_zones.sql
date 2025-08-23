create view price_tool_feed.[vw_zones]

as

select
    s.store_id,
    z.zone_id,
    z.zone_name
from
    price_tool_feed.zones z
join
    price_tool_feed.stores s
on
    (
        z.zone_id = s.zone_id
    )
GO
