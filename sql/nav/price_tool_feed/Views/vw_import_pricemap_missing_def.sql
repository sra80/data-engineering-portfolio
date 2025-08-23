create or alter view price_tool_feed.vw_import_pricemap_missing_def

as

select distinct 
    y_pt.price_type [Price Type],
    y_s.name [Store Name]
from 
    price_tool_feed.import_pricelist y_il
join
    price_tool_feed.import_pricetype y_pt
on
    (
        y_il.pricetype_id = y_pt.id
    )
join
    price_tool_feed.vw_stores y_s
on
    (
        y_il.store_id = y_s.store_id
    )
where
    (
        not exists (select 1 from price_tool_feed.import_pricemap y_ip where y_il.pricetype_id = y_ip.pricetype_id and y_il.store_id = y_ip.store_id)
    and not exists (select 1 from price_tool_feed.import_pricemap_exclude y_ipe where y_il.pricetype_id = y_ipe.pricetype_id and y_il.store_id = y_ipe.store_id)
    and y_il.external_id is null
    )