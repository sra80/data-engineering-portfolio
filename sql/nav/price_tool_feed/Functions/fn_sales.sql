create function [price_tool_feed].[fn_sales]
    (
        @year int
    )

returns table

as

return

select
    sa.id,
    sa.store_id,
    sa.article_id,
    sa.[date],
    case when 
            rf.[0] = 1
        or  rf.[1] = 1
        or  rf.[2] = 1
        or  rf.[3] = 1
        or  rf.[4] = 1
        or  rf.[5] = 1
    then
        99
    else
        sa.price_type
    end price_type,
    sa.quantity,
    sa.price,
    sa.shelf_price,
    sa.cost_price,
    sa.customer_id
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
    and year(sa.date) = @year
    )
GO
