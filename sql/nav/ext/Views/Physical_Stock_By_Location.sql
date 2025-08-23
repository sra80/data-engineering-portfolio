




CREATE view [ext].[Physical_Stock_By_Location]

as

select
	case when i.[Range Code] = '' then 'Not Specified' else i.[Range Code] end [Range Code] 
	,i.[Inventory Posting Group]
	,case [Status] when 0 then 'Prelaunch' when 1 then 'Active' when 2 then 'Discontinued' when 3 then 'Obsolete' when 4 then 'Rundown' else concat('Unknown Status (',[Status],')') end [Item Status]
	,ile.[Location Code]
	,ile.[Item No_] [Item No]
	,i.[Description] [Item Description]
	,ile.[Lot No_] [Batch No]
	,nullif(ile.[Expiration Date],datefromparts(1753,1,1)) [Batch Expiry Date]
	,case when nullif(ile.[Expiration Date],datefromparts(1753,1,1)) is not null then dateadd(day,-i.[Subscription Renewal Frequency],ile.[Expiration Date]) end [Batch Pull Date]
	,sum(ile.[Quantity]) [Quantity]
from
	[NAV_PROD_REPL].[dbo].[UK$Item] i (nolock)
join 
	[NAV_PROD_REPL].[dbo].[UK$Item Ledger Entry] ile (nolock)
on 
	i.[No_] = ile.[Item No_] 
where
	i.[No_] not like 'ZZ%'
and ile.[Location Code] in ('WASDSP','ONESTOP','AMAZON','AMZ SG','PROF')
and i.[Inventory Posting Group] in ('B2B ITEMS','FINISHED')
group by 
     i.[Range Code]
	,i.[Item Category Code]
	,i.[Inventory Posting Group]
	,i.[Status]
	,ile.[Location Code]
	,ile.[Lot No_]
	,ile.[Item No_] 
	,i.[Description]
	,ile.[Expiration Date]
	,i.[Subscription Renewal Frequency]
--having 
--	abs(sum(ile.[Quantity])) > 0
GO
