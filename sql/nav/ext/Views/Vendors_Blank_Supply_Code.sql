SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create or alter view [ext].[Vendors_Blank_Supply_Code]

as

select
	 [No_] [Vendor No]
	,[Name] [Vendor Name]
	,case
		when [Blocked] = 0 then 'No'
		when [Blocked] = 1 then 'Payment'
		when [Blocked] = 2 then 'All'
	end [Blocked]
from
	[NAV_PROD_REPL].[dbo].[UK$Vendor] (nolock)
where
	[Type of Supply Code] = ''

GO