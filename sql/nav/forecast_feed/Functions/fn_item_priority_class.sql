create or alter function forecast_feed.fn_item_priority_class
    (
        @item_id int
    )

returns table

as

return

with cte as
    (
        select
            r.ID range_id,
            item_id,
            dense_rank() over (partition by ii.[Range Code] order by s.new_quantity desc) new_quantity,
            dense_rank() over (partition by ii.[Range Code] order by s.sub_quantity desc) sub_quantity,
            dense_rank() over (partition by ii.[Range Code] order by s.all_quantity desc) all_quantity,
            dense_rank() over (partition by ii.[Range Code] order by s.sale_margin desc) sale_margin,
            dense_rank() over (partition by ii.[Range Code] order by s.sale_net desc) sale_net
        from
            (
                select
                    (select min(x) from (values(max(eomonth(_period))),(eomonth(getutcdate(),-1))) as x(x)) d_end
                from
                    forecast_feed.item_priority_class
            ) cal
        cross apply
            (
                select
                    item_id,
                    sum(new_quantity) new_quantity,
                    sum(sub_quantity) sub_quantity,
                    sum(all_quantity) all_quantity,
                    sum(sale_net-sale_cost) sale_margin,
                    sum(sale_net) sale_net
                from
                    forecast_feed.item_priority_class ips
                
                where
                    (
                        ips._period between eomonth(cal.d_end,-11) and cal.d_end
                    )
                group by
                    item_id
            ) s
        join
            ext.Item i
        on
            (
                s.item_id = i.ID
            )
        join
            hs_consolidated.[Item] ii
        on
            (
                i.company_id = ii.company_id
            and i.No_ = ii.No_
            )
        join
            ext.Range r
        on
            (
                ii.company_id = r.company_id
            and ii.[Range Code] = r.range_code
            )
        where
            (
                ii.[Status] = 1
            and ii.[Type] = 0
            and ii.[Inventory Posting Group] = 'FINISHED'
            )
    )
, p_a as
    (
        select
            cte.item_id
        from
            cte
        where
            (
                sub_quantity <= 30
            or  new_quantity <= 5
            or
                (
                    all_quantity <= 20
                and sale_margin <= 20
                and sale_net <= 20
                )
            )

        union all

        select
            i.ID
        from
            ext.Item i
        join
            hs_consolidated.[Item] ii
        on
            (
                i.company_id = ii.company_id
            and i.No_ = ii.No_
            )
        where
            (
                i.company_id = 1
            and ii.[Status] = 1
            and ii.[Type] = 0
            and ii.[Inventory Posting Group] = 'B2B ITEMS'
            )
    )
, p_b as
    (
        select
            i.ID item_id
        from
            ext.Item i
        join
            hs_consolidated.[Item] ii
        on
            (
                i.company_id = ii.company_id
            and i.No_ = ii.No_
            )
        where
            (
                i.company_id = 1
            and ii.[Status] = 1
            and ii.[Inventory Posting Group] = 'FINISHED'
            )

        except

        select
            p_a.item_id
        from
            p_a
    )
, p_abc as
    (
        select
            p_a.item_id,
            'A' priority_class
        from
            p_a

        union all

        select
            p_b.item_id,
            'B'
        from
            p_b

        union all

        select
            i.ID item_id,
            'C'
        from
            ext.Item i
        join
            hs_consolidated.[Item] ii
        on
            (
                i.company_id = ii.company_id
            and i.No_ = ii.No_
            )
        where
            (
                i.company_id = 1
            and ii.[Status] = 4
            and ii.[Inventory Posting Group] = 'FINISHED'
            )
    )

select
    x.item_id,
    y.priority_class
from
    (
        select
            @item_id item_id
    ) x
outer apply
    (
        select
            priority_class
        from
            p_abc
        where
            (
                p_abc.item_id = @item_id
            )
    ) y