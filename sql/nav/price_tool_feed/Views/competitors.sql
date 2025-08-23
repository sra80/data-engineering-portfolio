create or alter view [price_tool_feed].[competitors]

as
/*
select
    p.item_id article_id,
    p.partNo competitor_id,
    convert(date,pi.revTS) [date],
    compete_price competitor_price,
    0 competitor_price_type,
    c.competitor competitor_name,
    p.competitorURL [url],
    concat('Competitor Product Name: ',p.partName) detail,
    convert(bit,1 ^ pi.competitor_stock) competitor_oos
from
    price_tool_feed.pi_price_intelligence pi
join
    price_tool_feed.pi_product p
on
    (
        pi.product_id = p.id
    )
join
    price_tool_feed.pi_competitor c
on
    (
        p.competitor_id = c.id
    )
where
    (
        pi.is_current = 1
    )
*/

select
    p.item_id article_id,
    p.partNo competitor_id,
    nullif(p.CompetitorPackSize,0) CompetitorPackSize,
    nullif(p.CompetitorUnitSize,0) CompetitorUnitSize,
    nullif(p.CompetitorDosage,0) CompetitorDosage,
    convert(date,pi.revTS) [date],
    pi.compete_price competitor_price,
    pi.compete_rrp competitor_rrp,
    0 competitor_price_type,
    c.competitor competitor_name,
    p.competitorURL [url],
    concat('Competitor Product Name: ',p.partName) detail,
    convert(bit,1 ^ pi.competitor_stock) competitor_oos
from
    price_tool_feed.pi_price_intelligence pi
join
    price_tool_feed.pi_product p
on
    (
        pi.product_id = p.id
    )
join
    price_tool_feed.pi_competitor c
on
    (
        p.competitor_id = c.id
    )
where
    (
        pi.is_current = 1
    )