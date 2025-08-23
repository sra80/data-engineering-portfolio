
CREATE procedure [ext].[sp_CC_Sales]

as

insert into [ext].[CC_Sales] ([Document Type],[No_],[Doc_ No_ Occurrence],[Version No_],[Media Code],[Line No_],[Order Date],[Order Created by],[Channel Code],[Line Type],[Quantity])
select
	  sh.[Document Type]
	 ,sh.[No_]
	 ,sh.[Doc_ No_ Occurrence]
	 ,sh.[Version No_]
	 ,sh.[Media Code]
	 ,sl.[Line No_]
	 ,sh.[Order Date]
	 ,sh.[Order Created by]
	 ,sh.[Channel Code]
	 ,sl.[Line Type]
	 ,sl.[Quantity]
from 
	[dbo].[UK$Sales Header Archive] sh
join
	[dbo].[UK$Sales Line Archive] sl
on
	(
		sh.[Document Type] = sl.[Document Type]
	and sh.[No_] = sl.[Document No_]
	and sh.[Doc_ No_ Occurrence] = sl.[Doc_ No_ Occurrence]
	and sh.[Version No_] = sl.[Version No_]
	)
join
	[ext].[CC_Team_Members] cc
on
	(
		sh.[Order Created by] = cc.[User ID]
	)
where
	sh.[Archive Reason] = 3
and sh.[Order Date] >= dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))
and not exists (select 1 from [ext].[CC_Sales] x where x.[Document Type] = sh.[Document Type] and x.[No_] = sh.[No_] and x.[Doc_ No_ Occurrence] = sh.[Doc_ No_ Occurrence] and x.[Line No_] = sl.[Line No_])

delete from [ext].[CC_Sales] where [Order Date] < dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))

/*
Adding a new team member :

1) Insert a new team member into table below

insert into [ext].[CC_Team_Members] ([Team],[User ID],[User Name])
values 
	('Leading Lions','CompanyX\AMANDAM','Amanda Measey')
2) full load of sales required to include history
truncate table [ext].[CC_Sales]
insert into [ext].[CC_Sales] ([Document Type],[No_],[Doc_ No_ Occurrence],[Version No_],[Media Code],[Line No_],[Order Date],[Order Created by],[Channel Code],[Line Type],[Quantity])
select
	  sh.[Document Type]
	 ,sh.[No_]
	 ,sh.[Doc_ No_ Occurrence]
	 ,sh.[Version No_]
	 ,sh.[Media Code]
	 ,sl.[Line No_]
	 ,sh.[Order Date]
	 ,sh.[Order Created by]
	 ,sh.[Channel Code]
	 ,sl.[Line Type]
	 ,sl.[Quantity]
from 
	[dbo].[UK$Sales Header Archive] sh
join
	[dbo].[UK$Sales Line Archive] sl
on
	(
		sh.[Document Type] = sl.[Document Type]
	and sh.[No_] = sl.[Document No_]
	and sh.[Doc_ No_ Occurrence] = sl.[Doc_ No_ Occurrence]
	and sh.[Version No_] = sl.[Version No_]
	)
join
	[ext].[CC_Team_Members] cc
on
	(
		sh.[Order Created by] = cc.[User ID]
	)
where
	sh.[Archive Reason] = 3
and sh.[Order Date] >= dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))

*/
GO
