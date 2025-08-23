CREATE view [price_tool_feed].[vw_rejection_flags]

as

select
    rf.id,
    rf.[0],
    rf.[1],
    rf.[2],
    rf.[3],
    rf.[4],
    rf.[5]
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
        store_id in (select store_id from price_tool_feed.stores)
    and article_id in (select article_id from price_tool_feed.articles)
    and addTS >= convert(date,getutcdate())
    )
GO
