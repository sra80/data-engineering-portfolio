CREATE view [ext].[vw_Elite_Picking_Availability]

as

select
	 w.[Registering Date] [Replenishment Date]
	,w.[Location Code]
	,w.[Bin Code]
	,epa.[sku] [Item No]
	,i.[Description] [Item Description]
	,epa.[batchNo] [Lot No]
	,case
		when lni.[Test Quality] = 0 then ''
		when lni.[Test Quality] = 1 then 'Released'
		when lni.[Test Quality] = 2 then 'Stopped'
		when lni.[Test Quality] = 3 then 'Rejected'
		when lni.[Test Quality] = 4 then 'QA Required'
	 end [Test Quality]
	,lni.[Certificate Number]
	,w.[Unit of Measure Code]
	,format(w.[Quantity],'###,###,##0') [Quantity]
from
	[ext].[Elite_Picking_Availability] epa
join
	[dbo].[UK$Warehouse Entry] w
on
	(
		epa.[whseEntryNo] = w.[Entry No_]
	)
join
	[dbo].[UK$Lot No_ Information] lni
on
	(
		lni.[Item No_] = epa.sku
	and lni.[Lot No_] = epa.batchNo
	)
join
	[dbo].[UK$Item] i
on
	(
		epa.sku = i.[No_]
	)
join
	[db_sys].[email_notifications_schedule] ens
on
	(
		epa.[AddedTSUTC] >= ens.[last_processed]
	and ens.[ID] = 23
	)
GO
