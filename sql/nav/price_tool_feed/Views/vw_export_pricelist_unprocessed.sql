create or alter view price_tool_feed.vw_export_pricelist_unprocessed

as

select distinct 
    item_id 
from 
    price_tool_feed.import_pricelist 
where 
    (
        is_processed = 0
    and external_id_original is null
    )