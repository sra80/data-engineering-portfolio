
create or alter view [marketing].[Product]

as

select 
	e.ID key_sku,
	concat(case when iz.company_id = 1 then null else iz.company_id end,iz.No_) ord_itm,
	isnull(nullif(i.[Description],''),i.No_) [Item Name],
	isnull(ic.[Description],'Not categorised') [Item Category],
	isnull([Range].[Name],'Not set') [Item Range],
	isnull([Global Dimension 2 Code] + ' - ' + [reportingGroup].[Name],'Not set') [Item Reporting Group],
	[Global Dimension 1 Code] [Item Legal Entity],
	convert(bit,case when [Gen_ Prod_ Posting Group] = 'SERVICES' then 1 else 0 end) [Service],
    case [Status] when 0 then 'Prelaunch' when 1 then 'Active' when 2 then 'Discontinued' when 3 then 'Obsolete' when 4 then 'Rundown' else concat('Unknown Status (',[Status],')') end [Item Status],
    year(e.firstOrder) [First Order Year],
	e.firstOrder [First Order Date],
    i.[Inventory Posting Group],
	i.[Gross Weight] weight_gross,
	i.[Net Weight] weight_net,
    i.No_ [Item SKU],
	case when i.is_empty_d2 = 0 then i.url1 else i.url2 end [url]
from
	(select company_id, No_ from [hs_consolidated].[Item]) iz
join
    ext.Item e
on
    (
		iz.company_id = e.company_id
	and iz.[No_] = e.[No_]
	)
cross apply
    (
        select top 1
            company_id,
            No_,
            [Description],
			case when len([Description 2]) = 0 then 1 else 0 end [is_empty_d2],
			concat('https://www.CompanyX.co.uk/',lower(replace(replace(replace(replace(ltrim(rtrim(k.[Description 2])),' ','-'),'&','and'),',',''),'(R)',''))) [url1],
			concat('https://www.CompanyX.co.uk/search-results/?searchterm=',k.No_,'&searchterm_submit=Go') [url2],
            [Item Category Code],
            [Range Code],
            [Global Dimension 1 Code],
            [Global Dimension 2 Code],
            [Gen_ Prod_ Posting Group],
            [Status],
            [Inventory Posting Group],
			[Gross Weight],
			[Net Weight]
        from
            hs_consolidated.Item k
        where
            (
                iz.No_ = k.No_
            )
        order by
            company_id
    ) i
left join
	[hs_consolidated].[Item Category] ic
on
	(
		i.company_id = ic.company_id
	and i.[Item Category Code] = ic.Code
	)
left join
	[hs_consolidated].[Dimension Value] [range]
on
	(
		i.company_id = [range].company_id 
	and i.[Range Code] = [range].[Code] 
	and [range].[Dimension Code] = 'RANGE'
	)
left join
	[hs_consolidated].[Dimension Value] [reportingGroup]
on
	(
		i.company_id = [reportingGroup].company_id
	and i.[Global Dimension 2 Code] = [reportingGroup].[Code] 
	and [reportingGroup].[Dimension Code] = 'REP.GRP'
	)
GO
