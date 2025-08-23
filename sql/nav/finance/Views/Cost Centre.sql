






CREATE view [finance].[Cost Centre]

as	

--used in SalesInvoices model for Sale Channel
select 
	[Code], [Name] [Sale Channel]
from
	[dbo].[UK$Dimension Value] 
where
	[Dimension Code] = 'SALE.CHANNEL'
GO
