
CREATE view [forecast_feed].[bom]

as

select
    row_number() over (order by key_item,key_item_component) primary_key,
    key_item,
    key_item_component,
    component_qty,
    component_UoM,
    variant_code,
    lead_time_offset,
    key_location
from
    (
        select
            parent.ID key_item,
            child.ID key_item_component,
            y.[Quantity per] component_qty,
            y.[Unit of Measure Code] component_UoM,
            y.[Variant Code] variant_code,
            y.[Lead-Time Offset] lead_time_offset,
            w.[ID] key_location
        from
            [hs_consolidated].[Production BOM Header] x 
        join
            [hs_consolidated].[Production BOM Line] y
        on
            (
                x.company_id = y.company_id
            and x.[No_] = y.[Production BOM No_]
            and len([Version Code]) = 0
            )
        join
            ext.Item parent
        on
            (
                x.company_id = parent.company_id
            and x.[No_] = parent.No_
            )
        join
            hs_consolidated.Item parent2
        on
            (
                x.company_id = parent2.company_id
            and x.[No_] = parent2.No_
            and patindex('BUNDLE',parent2.[Base Unit of Measure]) = 0
            )
        join
            ext.Item child
        on
            (
                y.company_id = child.company_id
            and y.[No_] = child.[No_]
            )
        left join
            [ext].[Location] w
        on
            (
                y.company_id = w.company_id
            and y.[Location Code] = w.[location_code]
            )
        where
            (
                x.company_id = 1
            and x.[Status] < 3
            )

        union all

        select
            parent.ID key_item,
            child.ID key_item_component,
            bc.[Quantity per] [component_qty],
            bc.[Unit of Measure Code] [component_UoM],
            bc.[Variant Code] [variant_code],
            bc.[Lead-Time Offset] [lead_time_offset],
            isnull
                (
                    (select top 1 ID from ext.Location l where l.company_id = aa.company_id and l.location_code = aa.[Location Code]),
                    (select top 1 ID from ext.Location l where l.company_id = parent2.company_id and l.location_code = parent2.[Sales Location Code])
                ) key_location
        from
            hs_consolidated.[BOM Component] bc
        join
            ext.Item parent
        on
            (
                bc.company_id = parent.company_id
            and bc.[Parent Item No_] = parent.No_
            )
        join
            hs_consolidated.[Item] parent2
        on
            (
                bc.company_id = parent2.company_id
            and bc.[Parent Item No_] = parent2.No_
            )
        join
            ext.Item child
        on
            (
                bc.company_id = child.company_id
            and bc.No_ = child.No_
            )
        left join
           hs_consolidated.[Assembly Activation] aa
        on
            (
                aa.company_id = bc.company_id
            and aa.[Item No_] = bc.[Parent Item No_]
            and aa.[Channel Code] = 'WEB'
            ) 
        where
            (
                bc.company_id = 1
            )
    ) bom
where
    (
        bom.key_item in (select key_item from forecast_feed.item)
    and bom.key_item_component in (select key_item from forecast_feed.item)
    )
GO
