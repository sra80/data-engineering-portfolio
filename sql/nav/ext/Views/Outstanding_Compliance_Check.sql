CREATE view [ext].[Outstanding_Compliance_Check]

as

select 
	 sh.[No_] [Order No]
	,convert(nvarchar,sh.[Created DateTime],113) [Order Date]
	,sh.[Shipment Date] [Expected Shipment Date]
	,sh.[Sell-to Customer Name] [Customer Name]
	,[Ship-to Name] 
	,[Ship-to Name 2] + ' ' +  [Ship-to Address] + ' ' + [Ship-to Address 2] + ' ' + [Ship-to Post Code] + ' ' + [Ship-to City] + ' ' + [Ship-to County] + ' ' + [Ship-to Country_Region Code] [Ship-To Address]
	,sl.[Description] [Product Name]
	,convert(int,sl.[Quantity]) [Quantity]
from
	[NAV_PROD_REPL].[dbo].[UK$Sales Header] sh
join
	[NAV_PROD_REPL].[dbo].[UK$Sales Line] sl
on
	sh.[Document Type] = sl.[Document Type]
and sh.[No_] = sl.[Document No_]
where
	sh.[Document Type] = 1
--and sl.[Description] like 'THR%'
--and sh.[No_] = 'HO-56402652'
and patindex(sl.[No_],'ZZ%') = 0
and sh.[On Hold] = 'CPL'
and sh.[Compliance Check] = 1 --Required
GO
