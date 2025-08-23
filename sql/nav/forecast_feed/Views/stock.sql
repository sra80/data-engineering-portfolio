CREATE view [forecast_feed].[stock]

as

with stock_list as
    (
        select --all combinations of stock
            key_location,
            key_batch
        from
            forecast_feed.stock_history
        where
            is_current = 0

        union

        select --all combinations of components and associated locations with batch entries
            l.ID,
            child.ID
        from
        --     [hs_consolidated].[Production BOM Header] bph
        -- join
            hs_consolidated.[Production BOM Line]  pbl
        -- on
        --     (
        --         bph.company_id = pbl.company_id
        --     and bph.[No_] = pbl.[Production BOM No_]
        --     )
        join
            ext.Location l
        on
            (
                pbl.company_id = l.company_id
            and pbl.[Location Code] = l.location_code
            )
        -- join
        --     ext.Item_Batch_Info parent
        -- on
        --     (
        --         bph.company_id = parent.company_id
        --     and bph.No_ = parent.sku
        --     )
        join
            ext.Item_Batch_Info child
        on
            (
                pbl.company_id = child.company_id
            and pbl.No_ = child.sku
            )
        where 
            (
            --     bph.company_id = 1
            -- and 
                child.variant_code != 'dummy'
            -- and parent.item_ID in (select key_item from forecast_feed.item)
            and child.item_ID in (select key_item from forecast_feed.item)
            )

        union

        select --all combinations of components and associated locations with batch NO entries
            l.ID,
            child.ID
        from
        --     [hs_consolidated].[Production BOM Header] bph
        -- join
            hs_consolidated.[Production BOM Line]  pbl
        -- on
        --     (
        --         bph.company_id = pbl.company_id
        --     and bph.[No_] = pbl.[Production BOM No_]
        --     )
        join
            ext.Location l
        on
            (
                pbl.company_id = l.company_id
            and pbl.[Location Code] = l.location_code
            )
        -- join
        --     ext.Item_Batch_Info parent
        -- on
        --     (
        --         bph.company_id = parent.company_id
        --     and bph.No_ = parent.sku
        --     )
        join
            ext.Item_Batch_Info child
        on
            (
                pbl.company_id = child.company_id
            and pbl.No_ = child.sku
            )
        left join
            ext.Item_Batch_Info child_nobatch
        on
            (
                pbl.company_id = child_nobatch.company_id
            and pbl.No_ = child_nobatch.sku
            and child_nobatch.variant_code != 'dummy'
            ) 
        where 
            (
            --     bph.company_id = 1
            -- and 
                child.variant_code = 'dummy'
            and child.batch_no = 'Not Provided'
            and child_nobatch.company_id is null
            -- and parent.item_ID in (select key_item from forecast_feed.item)
            and child.item_ID in (select key_item from forecast_feed.item)
            )
    )

, date_list as
    (
        select
            max(closing_date) closing_date
        from
            forecast_feed.stock_history
        where
            is_current = 0
    )

, all_combos as
    (
        select
            sl.key_location,
            sl.key_batch,
            dl.closing_date
        from
            stock_list sl, date_list dl
    )

, forecast as
    (
        select
            ac.key_location,
            ac.key_batch,
            ac.closing_date,
            isnull(sh.units,0) units
        from
            all_combos ac
        left join
            (select key_location, units, key_batch, closing_date from forecast_feed.stock_history where is_current = 0) sh
        on
            (
                ac.key_location = sh.key_location
            and ac.key_batch = sh.key_batch
            and ac.closing_date = sh.closing_date
            )
    )

select
    row_number() over (order by f.closing_date, ibi.item_ID, f.key_location) primary_key,
    f.key_location,
    o.item_ID_overide key_item,
    ibi.batch,
    convert(nvarchar,isnull(ibi2.exp,datefromparts(2199,12,31)),103) [expiry_date],
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
    hs_consolidated.Item i
on
    (
        ibi.company_id = i.company_id
    and ibi.sku = i.No_
    )
join
    (
        select
            i.company_id,
            i.No_,
            min(i.ID) over (partition by i.No_) item_ID_overide
        from
            ext.Item i
    ) o
on
    (
        ibi.company_id = o.company_id
    and ibi.sku = o.No_
    )
-- outer apply
--     ext.fn_Item_Lifetime(ibi.company_id,ibi.sku,ibi.variant_code,ibi.batch_no,i.[Item Tracking Code],i.[Daily Dose],i.[Pack Size]) _dates
where
    (
        isnull(o.item_ID_overide,ibi.item_ID) in (select key_item from forecast_feed.item)
    )
GO
