create view price_tool_feed.price_3rdParty_greater_rrp

as

select
    item_name,
    rrp,
    -- [Agora],
    [Amazon Fbm],
    -- [Amazon Seller - Eu],
    -- [Amazon Seller - Singapore],
    [Amazon Seller - Uk],
    -- [British Corner Shop Ltd],
    -- [Dayrize Ltd],
    [Decathlon Uk],
    [Ebay],
    [Ebay Ireland],
    -- [Empathy Marketing Limited],
    [Fruugo],
    [Mellow],
    [Onbuy],
    -- [Petdreamhouse Ltd],
    [Sephora],
    [The Range]
from
    (
        select 
            s.store_name, 
            a.[name] item_name, 
            x.supplier_recommended_price rrp, 
            y.price shelf_price
        from 
            price_tool_feed.suppliers x 
        join 
            price_tool_feed.prices y 
        on 
            (
                x.store_id = y.store_id 
            and x.article_id = y.article_id
            ) 
        join 
            price_tool_feed.stores s 
        on 
            (
                x.store_id = s.store_id
            ) 
        join 
            price_tool_feed.articles a 
        on 
            (
                x.article_id = a.article_id
            ) 
        where 
            (
                x.supplier_recommended_price < y.price
            )
    ) u
pivot
    (
        min(shelf_price)
    for
        store_name in ([Agora],[Amazon Fbm],[Amazon Seller - Eu],[Amazon Seller - Singapore],[Amazon Seller - Uk],[British Corner Shop Ltd],[Dayrize Ltd],[Decathlon Uk],[Ebay],[Ebay Ireland],[Empathy Marketing Limited],[Fruugo],[Mellow],[Onbuy],[Petdreamhouse Ltd],[Sephora],[The Range])
    ) p
GO
