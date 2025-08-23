CREATE function [price_tool_feed].[fn_rejection_flags]
    (
        @year int
    )

returns table

as

return

select
    rf.id,
    db_sys.fn_bit_to_boolean(rf.[0]) [0],
    db_sys.fn_bit_to_boolean(rf.[1]) [1],
    db_sys.fn_bit_to_boolean(rf.[2]) [2],
    db_sys.fn_bit_to_boolean(rf.[3]) [3],
    db_sys.fn_bit_to_boolean(rf.[4]) [4],
    db_sys.fn_bit_to_boolean(rf.[5]) [5]
from
    price_tool_feed.sales_all sa
join
    price_tool_feed.sales_all_reject_flags rf
on
    (
        sa.id = rf.id
    )
where
    (
        sa.store_id in (select store_id from price_tool_feed.stores)
    and sa.article_id in (select article_id from price_tool_feed.articles)
    and year(sa.[date]) = @year
    )
GO
