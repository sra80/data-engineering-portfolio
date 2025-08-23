create or alter view stock.ProductPackaging

as

select
    ipt.key_posting_date,
    ipt.key_location,
    ipt.country_id,
    case when ipt.is_ic = 1 then 'Yes' else 'No' end [Intercompany Transfer],
    case when ipt.is_int = 1 then 'Yes' else 'No' end [International Shipment],
    case when ipt.is_amazon = 1 then 'Yes' else 'No' end [Amazon Shipment],
    ipt.key_batch,
    -- pack_type.[Package Type],
    pack_type.[Package Code],
    pack_type.[Package Description],
    pack_type.[Package Full],
    -- comp_type.[Component Type],
    comp_type.[Component Code],
    comp_type.[Component Description],
    comp_type.[Component Full],
    -- comp_material.[Component Material Type],
    comp_material.[Component Material Code],
    comp_material.[Component Material Description],
    comp_material.[Component Material Full],
    -- comp_mat_des.[Component Material Description Type],
    comp_mat_des.[Component Material Description Code],
    comp_mat_des.[Component Material Description Description],
    comp_mat_des.[Component Material Description Full],
    -- colour.[Colour Type],
    colour.[Colour Code],
    colour.[Colour Description],
    colour.[Colour Full],
    -- certification.[Certification Type],
    certification.[Certification Code],
    certification.[Certification Description],
    certification.[Certification Full],
    -- recycle_mat.[Recycled Materials Type],
    recycle_mat.[Recycled Materials Code],
    recycle_mat.[Recycled Materials Description],
    recycle_mat.[Recycled Materials Full],
    -- prod_type.[Producer Type],
    prod_type.[Producer Code],
    prod_type.[Producer Description],
    prod_type.[Producer Full],
    -- packing_type.[Packaging Type],
    packing_type.[Packaging Code],
    packing_type.[Packaging Description],
    packing_type.[Packaging Full],
    -- waste_type.[Waste Type],
    waste_type.[Waste Code],
    waste_type.[Waste Description],
    waste_type.[Waste Full],
    ip.[Material Weight (g) per unit] * try_convert(int,ip.[Component_Unit Count]) * ipt.quantity weight_grams
from
    stock.item_packaging_transactions ipt
join
    (
        select
            ext.fn_Item_Batch_Info(1, g.[Item No_], g.[Variant No_], g.[Lot No_]) key_batch,
            g.[Material Weight (g) per unit],
            g.[Component_Unit Count],
            g.[Package Type],
            g.[Component],
            g.[Component Material],
            g.[Component Material Desc_ Code],
            g.[Colour],
            g.[Certification Type],
            g.[Recycled Materials],
            g.[Producer Type],
            g.[Packaging Type],
            g.[Waste Type]
        from
            [hs_consolidated].[Item Packaging] g
    ) ip
on
    (
        ipt.key_batch = ip.key_batch
    )
outer apply
    (
        select
            -- [Type] [Package Type],
            [Code] [Package Code],
            [Description] [Package Description],
            concat([Description],' (',[Code],')') [Package Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'PACKAGE TYPE'
            and ip.[Package Type] = gl.Code
            )
    ) pack_type 
outer apply
    (
        select
            -- [Type] [Component Type],
            [Code] [Component Code],
            [Description] [Component Description],
            concat([Description],' (',[Code],')') [Component Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'COMPONENT'
            and ip.[Component] = gl.Code
            )
    ) comp_type
outer apply
    (
        select
            -- [Type] [Component Material Type],
            [Code] [Component Material Code],
            [Description] [Component Material Description],
            concat([Description],' (',[Code],')') [Component Material Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'COMPONENT MATERIAL'
            and ip.[Component Material] = gl.Code
            )
    ) comp_material
outer apply
    (
        select
            -- [Type] [Component Material Description Type],
            [Code] [Component Material Description Code],
            [Description] [Component Material Description Description],
            concat([Description],' (',[Code],')') [Component Material Description Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'COMP MATERIAL DESC'
            and ip.[Component Material] = 'OT'
            and ip.[Component Material Desc_ Code] = gl.Code
            )
    ) comp_mat_des
outer apply
    (
        select
            -- [Type] [Colour Type],
            [Code] [Colour Code],
            [Description] [Colour Description],
            concat([Description],' (',[Code],')') [Colour Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'COLOUR'
            and ip.[Colour] = gl.Code
            )
    ) colour
outer apply
    (
        select
            -- [Type] [Certification Type],
            [Code] [Certification Code],
            [Description] [Certification Description],
            concat([Description],' (',[Code],')') [Certification Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'CERTIFICATION TYPE'
            and ip.[Certification Type] = gl.Code
            )
    ) certification
outer apply
    (
        select
            -- [Type] [Recycled Materials Type],
            [Code] [Recycled Materials Code],
            [Description] [Recycled Materials Description],
            concat([Description],' (',[Code],')') [Recycled Materials Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'RECYCLED MATERIALS'
            and ip.[Recycled Materials] = gl.Code
            )
    ) recycle_mat
outer apply
    (
        select
            -- [Type] [Producer Type],
            [Code] [Producer Code],
            [Description] [Producer Description],
            concat([Description],' (',[Code],')') [Producer Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'PRODUCER'
            and ip.[Producer Type] = gl.Code
            )
    ) prod_type
outer apply
    (
        select
            -- [Type] [Packaging Type],
            [Code] [Packaging Code],
            [Description] [Packaging Description],
            concat([Description],' (',[Code],')') [Packaging Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'PACKAGING TYPE'
            and ip.[Packaging Type] = gl.Code
            )
    ) packing_type
outer apply
    (
        select
            -- [Type] [Waste Type],
            [Code] [Waste Code],
            [Description] [Waste Description],
            concat([Description],' (',[Code],')') [Waste Full]
        from
            dbo.[General Lookup] gl
        where
            (
                gl.[Type] = 'WASTE'
            and ip.[Waste Type] = gl.Code
            )
    ) waste_type