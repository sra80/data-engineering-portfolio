create   view [ext].[Full_Price_Missing]

as

select 
	 i.[No_] 
	,i.[Description] 
	,e.[firstOrder] [First Order Date]
	,case
		when i.[Status] = 0 then 'Prelaunch'
		when i.[Status] = 1 then 'Active'
		when i.[Status] = 4 then 'Rundown'
	 end [Status]
from 
	[UK$Item] i
left join 
	(select [Item No_] from [UK$Sales Price] where [Sales Code] = 'FULLPRICES')  f
on
	i.[No_] = f.[Item No_]
left join
	[ext].[Item] e
on
	e.company_id = 1
and i.[No_] = e.[No_]
where 
	i.[Inventory Posting Group] = 'FINISHED' 
--and i.[Range Code] != 'WIDGETS' 
and i.[Status] in (0,1,4)
and f.[Item No_] is null
and e.[firstOrder] >= datefromparts(year(getdate())-2,1,1)--is not null
GO
