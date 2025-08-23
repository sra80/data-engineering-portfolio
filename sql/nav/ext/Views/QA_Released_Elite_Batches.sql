CREATE view [ext].[QA_Released_Elite_Batches]

as

select 
     cle.[Date and Time] [Date and Time of Release]
    ,cle.[Primary Key Field 1 Value] [Item No]
	,i.[Description] [Item Description]
    ,cle.[Primary Key Field 3 Value] [Lot No]
	,x.[Expiration Date]
	,x.[Latest Despatch Date]
from
	[dbo].[UK$Change Log Entry] cle
join
	[dbo].[UK$Item] i
on
	(
		cle.[Primary Key Field 1 Value] = i.[No_]
	and i.[Range Code] = 'ELITE'
	)
join
	(
		select
				 ile.[Item No_] key_sku
				,ile.[Lot No_] [Batch Number]
				,max(ile.[Entry No_]) over (partition by ile.[Item No_],ile.[Lot No_]) last_entry
				,ile.[Entry No_]
				,case when i.[Item Tracking Code] = 'LOTALL' or ile.[Expiration Date] = DATEFROMPARTS(1753,1,1) then null else ile.[Expiration Date] end [Expiration Date]
				,case 
					when 
						i.[Item Tracking Code] = 'LOTALL' 
					then 
						null
					when 
						ile.[Latest Despatch Date] = DATEFROMPARTS(1753,1,1) 
					then
						case
							when
								i.[Item Tracking Code] = 'LOTALLEXP' 
							and ile.[Expiration Date] > DATEFROMPARTS(1753,1,1) 
							and i.[Daily Dose] > 0
						then
							dateadd(day,-((i.[Pack Size]/i.[Daily Dose])*1.1),ile.[Expiration Date]) -- buffer changed from 1.5 to 1.1 by SE @ 2021-08-02T14:03:06.5600341+03:00
						else
							null
						end
					else
						ile.[Latest Despatch Date]
					end [Latest Despatch Date]
			from
				[UK$Item Ledger Entry] ile
			join
				[UK$Item] i
			on
				(
					ile.[Item No_] = i.No_
				)
			where
				--[Entry Type] in (0,2,4,6)
				ile.Positive = 1
	) x
on
	(
		x.key_sku = cle.[Primary Key Field 1 Value]
	and x.[Batch Number] = cle.[Primary Key Field 3 Value]
	)
join
	[db_sys].[email_notifications_schedule] ens
on
	(
		cle.[Date and Time] >= isnull(ens.[last_processed],cle.[Date and Time])
	and ens.[ID] = 22
	)
where
	(
		cle.[Table No_] = 6505
	and cle.[Field No_] = 11
	and cle.[New Value] = 1
	and x.[Entry No_] = x.last_entry
	)
GO
