CREATE procedure price_tool_feed.sp_sales_all_reject_flags

as

set nocount on

declare @r int = 1

while @r > 0

begin

    insert into price_tool_feed.sales_all_reject_flags (id, [0], [1], [2], [3], [4], [5])
    select top 100000
        sa.id,
        case when sa.store_id = -1 then 1 else 0 end [0],
        case when sa.price <= sa.cost_price then 1 else 0 end [1],
        case when s.supplier_recommended_price < sa.shelf_price then 1 else 0 end [2],
        case when sa.cost_price = 0 then 1 else 0 end [3],
        case when sa.shelf_price = 0 then 1 else 0 end [4],
        case when t.zone_id in (1,2) and ia.is_anon = 0 then 1 else 0 end [5]
    from
        price_tool_feed.sales_all sa
    left join
        price_tool_feed.stores t
    on
        (
            sa.store_id = t.store_id
        )
    left join
        price_tool_feed.suppliers s
    on
        (
            sa.store_id = s.store_id
        and sa.article_id = s.article_id
        )
    cross apply
        (
            select top 1
                is_anon
            from
                hs_identity.Customer c
            where
                (
                    sa.customer_id = c.customer_id
                )
            order by
                is_anon desc
        ) ia
    where
        (
            sa.id not in (select id from price_tool_feed.sales_all_reject_flags)
        )

    set @r = @@rowcount

end
GO
