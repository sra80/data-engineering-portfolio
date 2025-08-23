CREATE or ALTER view [ext].[vw_IE_LowStock]

as

select
	 eos.sku [Item No]
	,i.[Description] [Item Description]
	,format(eos.[AvailableQuantity],'###,###,##0') [Available Stock]
from
	[ext].[IE_Outbound_Stock_Availability] eos
join
	[dbo].[IE$Item] i
on
	(
		eos.sku = i.[No_]
	and eos.[is_LowStock] = (select place_holder from db_sys.email_notifications_schedule where [ID] = 46)
	)
GO