
CREATE view [marketing].[Product_Attributes]

as

select
    e.ID  key_sku,
    ia.[Name] [Attribute],
    iav.[Value] [Attribute Value]
from
    [hs_consolidated].[Item Attribute Value Mapping] iavm 
join
    [hs_consolidated].[Item Attribute Value] iav
on
    (
        iavm.company_id = iav.company_id
    and iavm.[Item Attribute Value ID] = iav.[ID]
    )
join
    [hs_consolidated].[Item Attribute] ia
on
    (
        iavm.company_id = ia.company_id
    and	iavm.[Item Attribute ID] = ia.[ID]
    )
join
    ext.Item e
on
    (
        iavm.company_id = e.company_id
    and iavm.[No_] = e.[No_]
    )
GO
