create or alter view [forecast_feed].[item]

as

select
	ei.[ID] [key_item],
    i.[No_] [item_code],
	i.[Description] [item_description],
	case i.[Status] 
		when 0 then 'Prelaunch' 
		when 1 then 'Active' 
		when 2 then 'Discontinued' 
		when 3 then 'Obsolete' 
		when 4 then 'Rundown' 
		else concat('Unknown Status (',[Status],')') 
	end [status],
	i.[Inventory Posting Group] [inventory_posting_group],
	i.[Range Code] [range_code],
    case i.[Replenishment System]
		when 0 then 'Purchase'
		when 1 then 'Prod_Order'
		when 3 then 'Assembly'
	else concat('Unknown (',[Replenishment System],')') 
	end [replenishment_system],
    i.[Routing No_] [routing_no_],
	bg.[Value] [item_budget_group],
	case
		when [Inventory Posting Group] in ('FINISHED','B2B ITEMS') then 1
		when [Inventory Posting Group] = 'PACK' then 2
		when [Inventory Posting Group] = 'BULK' then 3
		when [Inventory Posting Group] = 'RAW' then 4
	else 5
	end [key_level],
	i.[Vendor No_] [vendor_no],
    isnull((select top 1 [Cross-Reference No_] from [dbo].[UK$Item Cross Reference] icr where icr.[Cross-Reference Type] = 2 and i.No_ = icr.[Item No_] and i.[Vendor No_] = icr.[Cross-Reference Type No_]),'') vendor_item_code,
    isnull(ipc.priority_class,'') priority_class
from
    (
        select
            No_,
            min(ID) ID,
            min(company_id) company_id,
            max(lastOrder) lastOrder
        from
            ext.Item
        group by
            No_
    ) ei
join
    (
        select
            company_id,
            [No_],
            [Description],
            [Status],
            [Inventory Posting Group],
            [Range Code],
            [Replenishment System],
            [Routing No_],
            [Vendor No_],
            [Type]
        from
            [hs_consolidated].[Item]
        where
            (
                patindex('BUNDLE',[Item].[Base Unit of Measure]) = 0
            and [Global Dimension 2 Code] != 110
            )
    ) i
on
    (
        ei.company_id = i.company_id
    and ei.No_ = i.No_
    )
join
    ext.Range r
on
    (
        i.company_id = r.company_id
    and i.[Range Code] = r.range_code
    )
left join
	(
        select
            iavm.company_id,
            iavm.[No_],
            iav.[Value]
        from
            [hs_consolidated].[Item Attribute Value Mapping] iavm
        join
            [hs_consolidated].[Item Attribute Value] iav
        on
            (
                iavm.company_id = iav.company_id
            and iavm.[Item Attribute ID] = 27
            and iavm.[Table ID] = 27
            and iavm.[Item Attribute Value ID] = iav.[ID]
            )
	) bg
on
	(
        ei.company_id = bg.company_id
    and i.[No_] = bg.[No_]
    )
cross apply
    forecast_feed.fn_item_priority_class(ei.ID) ipc
where
    (
        (
            ei.lastOrder >= datefromparts(year(getutcdate())-4,1,1)
        or  
            (
                ei.lastOrder is null --added 20/07/2023 @ 12:49 GMT by SE to include new product that has not yet had a sale
            and i.[Status] in (0,1)
            )
        )
     --convert(date,dateadd(year,-1,getdate()))
    /*Above agreed with Adam & Anil, only including the last year affects historical transactions that go back further, sales data goes back 5 years*/
    and i.[Type] = 0
    and i.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
    and r.is_inc_anaplan = 1
    )

union all

select
	ei.[ID] [key_item],
    i.[No_] [item_code],
	i.[Description] [item_description],
	case i.[Status] 
		when 0 then 'Prelaunch' 
		when 1 then 'Active' 
		when 2 then 'Discontinued' 
		when 3 then 'Obsolete' 
		when 4 then 'Rundown' 
		else concat('Unknown Status (',[Status],')') 
	end [status],
	i.[Inventory Posting Group] [inventory_posting_group],
	i.[Range Code] [range_code],
    case i.[Replenishment System]
		when 0 then 'Purchase'
		when 1 then 'Prod_Order'
		when 3 then 'Assembly'
	else concat('Unknown (',[Replenishment System],')') 
	end [replenishment_system],
    i.[Routing No_] [routing_no_],
	bg.[Value] [item_budget_group],
	case
		when i.[Inventory Posting Group] in ('FINISHED','B2B ITEMS') then 1
		when i.[Inventory Posting Group] = 'PACK' then 2
		when i.[Inventory Posting Group] = 'BULK' then 3
		when i.[Inventory Posting Group] = 'RAW' then 4
	else 5
	end [key_level],
	i.[Vendor No_] [vendor_no],
    isnull((select top 1 [Cross-Reference No_] from [dbo].[UK$Item Cross Reference] icr where icr.[Cross-Reference Type] = 2 and i.No_ = icr.[Item No_] and i.[Vendor No_] = icr.[Cross-Reference Type No_]),'') vendor_item_code,
    isnull(ipc.priority_class,'') priority_class
from
    (
        select
            No_,
            min(ID) ID,
            min(company_id) company_id,
            max(lastOrder) lastOrder
        from
            ext.Item
        group by
            No_
    ) ei
join
    (
        select
            company_id,
            [No_],
            [Description],
            [Status],
            [Inventory Posting Group],
            [Range Code],
            [Replenishment System],
            [Routing No_],
            [Vendor No_],
            [Type]
        from
            [hs_consolidated].[Item]
        where
            (
                patindex('BUNDLE',[Item].[Base Unit of Measure]) = 0
            and [Global Dimension 2 Code] != 110
            )
    ) i
on
    (
        ei.company_id = i.company_id
    and ei.No_ = i.No_
    )
join
    ext.Range r
on
    (
        i.company_id = r.company_id
    and i.[Range Code] = r.range_code
    )
left join
	(
        select
            iavm.company_id,
            iavm.[No_],
            iav.[Value]
        from
            [hs_consolidated].[Item Attribute Value Mapping] iavm
        join
            [hs_consolidated].[Item Attribute Value] iav
        on
            (
                iavm.company_id = iav.company_id
            and iavm.[Item Attribute ID] = 27
            and iavm.[Table ID] = 27
            and iavm.[Item Attribute Value ID] = iav.[ID]
            )
	) bg
on
	(
        ei.company_id = bg.company_id
    and i.[No_] = bg.[No_]
    )
cross apply
    forecast_feed.fn_item_priority_class(ei.ID) ipc
where
	i.[Type] = 0
and i.[Inventory Posting Group] not in ('FINISHED','B2B ITEMS')
and r.is_inc_anaplan = 1
GO
