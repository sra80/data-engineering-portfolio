create or alter view [ext].[Sales_Price_Missing]

as

--adopted by SE from A37_itemsNoSellPrice @ 

select 
	i.[No_] [Item Code],
	i.[Description] [Item Description],
	case when d.[Item No_] is null or d.[Ending Date] < getutcdate() and (channels.[PHONE] = 1 or channels.[WEB] = 1) then concat('No',case when d.[Ending Date] is not null then concat('<p>(last price ended ',format(d.[Ending Date],'dd/MM/yyyy'),')') end) else 'Yes' end [Default<br>Price],
	case when f.[Item No_] is null or f.[Ending Date] < getutcdate() then concat('No',case when f.[Ending Date] is not null then concat('<p>(last price ended ',format(f.[Ending Date],'dd/MM/yyyy'),')') end) else 'Yes' end [Full<br>Price],
	case when s.[Item No_] is null or s.[Ending Date] < getutcdate() then case when i.[Subscribe and Save] = 1 and channels.[REPEAT] = 1 then concat('No',case when s.[Ending Date] is not null then concat('<p>(last price ended ',format(s.[Ending Date],'dd/MM/yyyy'),')') end) else 'n/a' end else 'Yes' end [Subscribe<br>&amp Save<br>Price],
	case when row_number() over (order by i.[No_])%2 = 0 then '#D9E1F2' else '#FFFFFF' end bg
from 
	[dbo].[UK$Item] i
join
	(
		select 
			[Item No_],
			[PHONE],
			[WEB],
			[REPEAT]
		from 
			(
				select
					[Item No_],
					[Channel Code],
					1 is_active
				from
					[dbo].[UK$Item Channel]
				where
					(
						[Channel Code] in ('PHONE','WEB','REPEAT')
					)
			) u
		pivot
			(
				max(is_active)
			for
				[Channel Code] in ([PHONE],[WEB],[REPEAT])
			) p
	) channels
on
	(
		i.No_ = channels.[Item No_]
	)
outer apply
	(select top 1 [Item No_], [Ending Date] from [dbo].[UK$Sales Price] d where [Sales Code] = 'DEFAULT' and i.[No_] = d.[Item No_] order by [Ending Date] desc) d
outer apply
	(select top 1 [Item No_], [Ending Date] from [dbo].[UK$Sales Price] f where [Sales Code] = 'FULLPRICES' and i.[No_] = f.[Item No_] order by [Ending Date] desc)  f
outer apply
	(select top 1 [Item No_], [Ending Date] from [dbo].[UK$Sales Price] s where [Sales Code] = 'SUBDEFAULT ' and i.[No_] = s.[Item No_] and [Ending Date] >= getutcdate()) s
where 
	(
        i.[Inventory Posting Group] = 'FINISHED' 
    and i.[Range Code] != 'WIDGETS' 
    and i.[Status] in (1)
    and 
        (
            (
				d.[Item No_] is null
			or	d.[Ending Date] < getutcdate()
			)
        or  (
				f.[Item No_] is null
			or	f.[Ending Date] < getutcdate()
			)
        or  
			(
				(
					s.[Item No_] is null 
				and  i.[Subscribe and Save] = 1
				)
			or	s.[Ending Date] < getutcdate()
			)
        )
    )
GO
