
CREATE   view [forecast_feed].[moq]

as

select
	row_number() over (order by ei.[ID]) primary_key,
	i.[Vendor No_] [key_vendor],
	ei.[ID] [key_item],
	p.[Minimum Quantity] [moq]
from
    [hs_consolidated].[Item] i
join
	[ext].[Item] ei
on
	(
        i.company_id = ei.company_id
    and i.[No_] = ei.[No_]
	)
join
	[hs_consolidated].[Purchase Price] p
on
    (
        i.company_id = p.company_id
    and i.[Vendor No_] = p.[Vendor No_]
    and i.[No_] = p.[Item No_]
    and p.[Ending Date] = '17530101'
    )
where
	(
        ei.[ID] in (select key_item from forecast_feed.item)
	)
GO
