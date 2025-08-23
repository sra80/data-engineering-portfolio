create view forecast_feed.item_batch_info

as

select company_id, ID, sku, item_ID, variant_code, batch_no, concat(isnull(nullif(nullif(batch_no,''),'Not Provided'),concat('db_'/*stands for dummy batch*/,ID)),case when len(variant_code) > 0 then concat('_',variant_code) else '' end) batch from ext.Item_Batch_Info
GO
