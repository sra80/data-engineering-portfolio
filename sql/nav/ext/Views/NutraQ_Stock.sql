SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create or alter view [ext].[NutraQ_Stock]

as

/* changes below made due to products with no batch not appearing in the output NQFLY-9005,NQFLY-9006,NQFLY-9007,NQFLY-9008*/

select
    ibi.sku [Item No],
    i.[Description] [Item Description],
    ibi.batch_no [Batch No],
    format(ile.Quantity,'###,###,##0') [Available Stock]
from
    hs_consolidated.[Item] i
join
  ext.Item_Batch_Info ibi
on
    (
        i.company_id = ibi.company_id
    and i.No_ = ibi.sku
    )
cross apply
    (
        select
            isnull(sum(ceiling(Quantity)),0) Quantity
        from
            hs_consolidated.[Item Ledger Entry] ile
        where
            (
                ibi.[company_id] = ile.[company_id]
            and ibi.sku = ile.[Item No_]
            and ibi.batch_no = isnull(nullif(ile.[Lot No_],''),'Not Provided')----ile.[Lot No_] 
            and 
                (
                    ibi.variant_code = ile.[Variant Code]
                or
                    ibi.variant_code = 'dummy'
                )
            )
    ) ile
where
    (
        i.[Global Dimension 2 Code] = '110'
    and ile.Quantity > 0
        -- (
        --         -- nullif(ibi.variant_code,'') is null
        --     or ibi.[batch_no] = 'Not Provided'
        -- )
    )
GO