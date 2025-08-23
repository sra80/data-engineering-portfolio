CREATE view [price_tool_feed].[suppliers]

as

select 
    s.store_id,
    fullprice.article_id,
    fullprice.price -
        case when
            s.is_sub = 0 
        then
            0
        else
            ss_discount.discount
        end supplier_recommended_price
from 
    price_tool_feed.stores s
,
    (
        select
            i.ID article_id,
            convert(money,round(min([Unit Price]),2)) price
        from
            dbo.[UK$Sales Price] sp
        join
            (select ID, No_ from ext.Item where company_id = 1) i
        on
            (
                i.No_ = sp.[Item No_]
            )
        where
            (
                sp.[Item No_] = i.No_
            and sp.[Sales Type] = 1
            and sp.[Sales Code] = 'FULLPRICES'
            and sp.[Starting Date] <= convert(date,getutcdate())
            and sp.[Ending Date] >= convert(date,getutcdate())
            and i.ID in (select article_id from price_tool_feed.articles)
            )
        group by
            i.ID
    ) fullprice
cross apply
    (
        select 
            max(discount.discount) discount
        from
            (
                select
                    0 price, 0 discount
                union all
                select
                    1, 1
                union all
                select
                    10, 2
                union all
                select
                    20, 3
                union all
                select
                    30, 4
                union all
                select
                    40, 6
            ) discount
        where
            fullprice.price >= discount.price
    ) ss_discount
where
    (
        fullprice.price > 0
    )
GO
