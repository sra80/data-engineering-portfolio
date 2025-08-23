CREATE view [forecast_feed].[stock_current]

as

with forecast as
    (
        select
            sh.key_location,
            sh.key_batch,
            sh.closing_date,
            sh.units
        from
            forecast_feed.stock_history sh
        where
            is_current = 1
    )

select
    row_number() over (order by f.closing_date, ibi.item_ID, f.key_location) primary_key,
    f.key_location,
    isnull(ioa.item_ID_overide,ei.ID) key_item,
    ibi.batch,
    convert(nvarchar,isnull(ibi2.[exp],datefromparts(2199,12,31)),103) [expiry_date],
    convert(nvarchar,isnull(ibi2.ldd,datefromparts(2199,12,31)),103) [latest_despatch_date],
    f.units
from
    forecast f
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
join
    ext.Item ei
on
    (
        ibi.company_id = ei.company_id
    and ibi.sku = ei.No_
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
        isnull(ioa.item_ID_overide,ei.ID) in (select key_item from forecast_feed.item)
    )
GO
