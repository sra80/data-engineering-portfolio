create view price_tool_feed.vw_rejection_flags_lookup

as

select
    id,
    [definition]
from
    price_tool_feed.reject_flags_lookup
GO
