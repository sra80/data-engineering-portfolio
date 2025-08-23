CREATE view [forecast_feed].[stock_history_view]

as

select
    concat(convert(nvarchar,f.closing_date,103),'_',f.key_location,'_',ibi.item_ID,'_',ibi.batch) primary_key,
    convert(nvarchar,f.closing_date,103) closing_date,
    f.key_location,
    isnull(ioa.item_ID_overide,ibi.item_ID) key_item,
    ibi.batch,
    convert(nvarchar,isnull(ibi2.exp,datefromparts(2199,12,31)),103) [expiry_date],
    convert(nvarchar,isnull(ibi2.ldd,datefromparts(2199,12,31)),103) [latest_despatch_date],
    f.units
from
    forecast_feed.stock_history f
join
    forecast_feed.item_batch_info ibi
on
    (
        f.key_batch = ibi.ID
    )
join
    ext.Item_Batch_Info ibi2
on
    (
        ibi.ID = ibi2.ID
    )
left join
    forecast_feed.item_overide_aggregate ioa
on
    (
        ibi.item_ID = ioa.item_ID
    )
join
    hs_consolidated.Item i
on
    (
        ibi.company_id = i.company_id
    and ibi.sku = i.No_
    )
-- outer apply
--     ext.fn_Item_Lifetime(ibi.company_id,ibi.sku,ibi.variant_code,ibi.batch_no,i.[Item Tracking Code],i.[Daily Dose],i.[Pack Size]) _dates
where
    (
        f.is_current = 0
    and isnull(ioa.item_ID_overide,ibi.item_ID) in (select key_item from forecast_feed.item)
    )
GO
