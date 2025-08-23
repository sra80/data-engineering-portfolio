create or alter view [price_tool_feed].[vw_sales]

as

select
    convert(int,ceiling(db_sys.fn_divide(r,100000,0))) _file,
    sa.id,
    sa.store_id,
    sa.article_id,
    sa.[date],
    sa.price_type,
    sa.quantity,
    sa.price,
    sa.shelf_price,
    sa.cost_price,
    sa.customer_id,
    rf.[0],
    rf.[1],
    rf.[2],
    rf.[3],
    rf.[4],
    rf.[5]
from
    (
        select 
            row_number() over (order by id) r,
            id,
            store_id,
            article_id,
            [date],
            price_type,
            quantity,
            price,
            shelf_price,
            cost_price,
            customer_id
        from 
            price_tool_feed.sales_all
        where
            (
                store_id in (select store_id from price_tool_feed.stores)
            and article_id in (select article_id from price_tool_feed.articles)
            and [date] >= dateadd(month,-1,getutcdate())
            )
    ) sa
join
    price_tool_feed.sales_all_reject_flags rf
on
    (
        sa.id = rf.id
    )
GO
