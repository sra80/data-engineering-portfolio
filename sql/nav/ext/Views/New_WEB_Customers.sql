

CREATE or ALTER VIEW [ext].[New_WEB_Customers]

as

select
	 ec.[cus] [Customer No]
	,c.[Created Date] [Customer Create Date]
	,ish.[Document No_] [Order No]
	,ish.[Origin Datetime] [Order Created Date]
from
	[ext].[Customer] ec
join
	[dbo].[UK$Customer] c
on
	(
		ec.[cus] = c.[No_]
	)
join
	[dbo].[UK$Inbound Sales Header] ish

on
	ec.[cus] = ish.[Customer No_]
where
	[first_channel_code] = 'WEB'
and c.[Created Date] > getdate()-9
GO
