
create or alter procedure [price_tool_feed].[sp_cross_check]

as

set nocount on

merge price_tool_feed.cross_check t
using 
    (
        select
            dateadd(day,1,eomonth(sa.[date],-1)) [month],
            a.parent_category_id category_id,
            sa.store_id,
            sum(sa.quantity) total_quantity,
            sum(price*quantity) total_revenue,
            sum(price*quantity)-sum(cost_price*quantity) total_profit
        from
            price_tool_feed.sales_all sa
        join
            price_tool_feed.articles a
        on
            (
                sa.article_id = a.article_id
            )
        where
            (
                a.parent_category_id is not null
            )
        group by
            dateadd(day,1,eomonth(sa.[date],-1)),
            a.parent_category_id,
            sa.store_id
    ) s
on
    (
        s.[month] = t.[month]
    and s.category_id = t.category_id
    and s.store_id = t.store_id
    )
when not matched then insert ([month], category_id, store_id, total_quantity, total_revenue, total_profit)
values (s.[month], s.category_id, s.store_id, s.total_quantity, s.total_revenue, s.total_profit)
when matched and (s.total_quantity != t.total_quantity or s.total_revenue != t.total_revenue or s.total_profit != t.total_profit) then
update set
    t.total_quantity = s.total_quantity,
    t.total_revenue = s.total_revenue,
    t.total_profit = s.total_profit,
    t.revTS = sysdatetime();
GO
