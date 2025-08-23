create or alter view [price_tool_feed].[prices]

as

select
    s.store_id,
    a.article_id,
    case when 
        s.is_sub = 0 
    then 
        price.price 
    else 
        (
            select 
                min(price) 
            from 
                (
                    values
                        (price.price),
                        (fullprice.price-ss_discount.discount),
                        (ss1storder.price)
                ) as x(price)
        ) end price,
    ext.fn_Item_UnitCost(a.article_id, default) cost_price
from
    price_tool_feed.stores s
join
    price_tool_feed.zones z
on
    (
        s.zone_id = z.zone_id
    )
cross apply 
    price_tool_feed.articles a
left join
    (
        select 
            c.customer_id,
            x.[Customer Price Group] 
        from 
            price_tool_feed.stores s 
        join 
            hs_identity.Customer c 
        on 
            (
                s.customer_id = c.customer_id
            )
        join 
            hs_identity_link.Customer_NAVID n 
        on 
            (
                c.nav_id = n.ID
            ) 
        join 
            [dbo].[UK$Customer] x 
        on 
            (
                n.company_id = 1 
            and n.nav_code = x.No_
        )
    ) cpg
on
    (
        s.customer_id = cpg.customer_id
    )
outer apply
    (
        select
            convert(money,round(min([Unit Price]),2)) price
        from
            [dbo].[UK$Sales Price] sp
        join
            ext.Item i
        on
            (
                i.company_id = 1
            and sp.[Item No_] = i.No_
            )
        where
            (
                i.ID = a.article_id
            and sp.[Sales Type] = 1
            and sp.[Sales Code] = isnull(cpg.[Customer Price Group],'DEFAULT')
            and sp.[Starting Date] <= convert(date,getutcdate())
            and sp.[Ending Date] >= convert(date,getutcdate())
            )
    ) price
outer apply
    (
        select
            convert(money,round(min([Unit Price]),2)) price
        from
            [dbo].[UK$Sales Price] sp
        join
            ext.Item i
        on
            (
                i.company_id = 1
            and sp.[Item No_] = i.No_
            )
        where
            (
                i.ID = a.article_id
            and sp.[Sales Type] = 1
            and sp.[Sales Code] = 'FULLPRICES'
            and sp.[Starting Date] <= convert(date,getutcdate())
            and sp.[Ending Date] >= convert(date,getutcdate())
            )
    ) fullprice
outer apply
    (
        select
            convert(money,round(min([Unit Price]),2)) price
        from
            [dbo].[UK$Sales Price] sp
        join
            ext.Item i
        on
            (
                i.company_id = 1
            and sp.[Item No_] = i.No_
            )
        where
            (
                i.ID = a.article_id
            and sp.[Sales Type] = 1
            and sp.[Sales Code] = 'SS1STORDER'
            and sp.[Starting Date] <= convert(date,getutcdate())
            and sp.[Ending Date] >= convert(date,getutcdate())
            and z.zone_name = 'Subs 1st Order'
            )
    ) ss1storder
outer apply
    (
        select 
            max(discount.discount) discount
        from
            price_tool_feed.subs_fixed_discount discount
        where
            fullprice.price >= discount.price
    ) ss_discount
where
    (
        price.price > 0
    and fullprice.price > 0
    and ext.fn_Item_UnitCost(a.article_id, default) > 0
    )
GO
