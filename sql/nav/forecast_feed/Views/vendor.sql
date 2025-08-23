




CREATE VIEW [forecast_feed].[vendor]

as

select
	 [No_] [vendor_no]
	,[Name] [vendor_name]
	,[Lead Time Calculation] [lead_time_calculation]
from
	[NAV_PROD_REPL].[dbo].[UK$Vendor]
where
	[Type of Supply Code] = 'PROCUREMNT'
and [Blocked] = 0
GO
