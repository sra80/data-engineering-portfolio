create or alter view [finance].[Product]

as

select 
	e.ID keySKU,
    i.[No_] [Item No],
	i.[Description] collate SQL_Latin1_General_CP1_CI_AS [Item Name],
    isnull(ibg.[Value],'Not categorised') [Item Category],
    isnull(ibg.[Value],'Not set') [Item Budget Group],
	isnull([Range].[Description],'Not set') [Item Range],
	i.[Inventory Posting Group],
	case when i.[Gen_ Prod_ Posting Group] = 'SERVICES' then 1 else 0 end [Service],
    case [Status] when 0 then 'Prelaunch' when 1 then 'Active' when 2 then 'Discontinued' when 3 then 'Obsolete' when 4 then 'Rundown' else concat('Unknown Status (',[Status],')') end collate SQL_Latin1_General_CP1_CI_AS [Item Status],
	o_gb_direct.availableStock [Available Stock UK],
	o_gb_direct.lastSale [Last Sale UK],
    e.company_id,
    i.[Status] [item_status_key]
from
    ext.Item e
join
	[hs_consolidated].[Item] i
on
    (
        e.company_id = i.company_id
    and e.No_ = i.No_
    )
left join
	[hs_consolidated].[Item Category] ic
on
	(
        i.company_id = ic.company_id
    and i.[Item Category Code] = ic.[Code]
    )
left join
	[hs_consolidated].[Range] [Range] 
on
    (
        i.company_id = [Range].company_id
    and i.[Range Code] = [Range].[Code]
    )
left join
	ext.Item_OOS o_gb_direct
on
	(
        i.company_id = 1
    and i.No_ = o_gb_direct.sku 
    and o_gb_direct.is_current = 1 
    and o_gb_direct.country = 'GB' 
    and o_gb_direct.distribution_type = 'DIRECT'
    )
outer apply
    (
        select top 1
            iav.[Value]
        from
            hs_consolidated.[Item Attribute] ia
        join
            hs_consolidated.[Item Attribute Value] iav
        on
            (
                ia.company_id = iav.company_id
            and ia.ID = iav.[Attribute ID]
            )
        join
            hs_consolidated.[Item Attribute Value Mapping] iavm
        on
            (
                iav.company_id = iavm.company_id
            and iav.[Attribute ID] = iavm.[Item Attribute ID]
            and iav.ID = iavm.[Item Attribute Value ID]
            )
        where
            (
                ia.[Name] = 'Item Budget Group'
            and ia.company_id = i.company_id
            and iavm.No_ = i.No_
            )
    ) ibg
GO
