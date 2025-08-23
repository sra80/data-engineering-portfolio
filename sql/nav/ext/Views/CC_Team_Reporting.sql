

ALTER view [ext].[CC_Team_Reporting]

as
	select
		 convert(date,sh.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,0 [Open Sales Orders]
		,0 [Open Return Orders]
		,case
			when sh.[Channel Code] = 'SCAN' then count(sh.[No_]) else 0
		 end [Scanned Orders]
        ,case
			when sh.[Channel Code] = 'OUTBOUND' then count(sh.[No_]) else 0
		 end [Outbound Orders]
		,case
			when sh.[Media Code] = 'HXSELL50' then count(sh.[No_]) else 0
		 end [50% off New Item]
		,0 [Email Captured]
		,0 [Email Deleted]
		,0 [Email Modified]
		,0 [S&S Set Up]
		,0 [Alternative Quantity]
		,0 [UpSell Quantity]
		,0 [CrossSell Quantity]
		,0 [Email Opt Ins]
		,0 [Email Opt Outs]
		,0 [Mail Opt Ins]
		,0 [Phone Opt Ins]
		,0 [Basket Increase]
		,0 [PI Conversion]
		,0 [S&S Rescue]
	from 
		[dbo].[UK$Sales Header] sh
	join
		[ext].[CC_Team_Members] cc
	on
		(
			sh.[Created by] = cc.[User ID]
		)
	where
		sh.[Document Type] = 1
	and sh.[Sales Order Status] = 1
	and sh.[Order Date] >= dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))
	and 
		(
			sh.[Channel Code] in ('SCAN','OUTBOUND')
		 or sh.[Media Code] = 'HXSELL50'
		)
	group by
		 convert(date,sh.[Order Date])
		,cc.[User Name]
		,cc.[Team]
		,sh.[Channel Code]
		,sh.[Media Code]

	union all

	select
		 convert(date,cs.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,0 [Open Sales Orders]
		,0 [Open Return Orders]
		,case
			when cs.[Channel Code] = 'SCAN' then count(distinct(cs.[No_]))
			else 0
		 end [Scanned Orders]
        ,case
			when cs.[Channel Code] = 'OUTBOUND' then count(distinct(cs.[No_])) else 0
		 end [Outbound Orders]
		,case
			when cs.[Media Code] = 'HXSELL50' then count(distinct(cs.[No_]))
			else 0
		 end [50% off New Item]
		,0 [Email Captured]
		,0 [Email Deleted]
		,0 [Email Modified]
		,0 [S&S Set Up]
		,0 [Alternative Quantity]
		,0 [UpSell Quantity]
		,0 [CrossSell Quantity]
		,0 [Email Opt Ins]
		,0 [Email Opt Outs]
		,0 [Mail Opt Ins]
		,0 [Phone Opt Ins]
		,0 [Basket Increase]
		,0 [PI Conversion]
		,0 [S&S Rescue]
	from 
		[ext].[CC_Sales] cs
	join
		[ext].[CC_Team_Members] cc
	on
		(
			cs.[Order Created by] = cc.[User ID]
		)
	--where
	--	cs.[Channel Code] = 'SCAN'
	group by
		 convert(date,cs.[Order Date])
		,cc.[User Name]
		,cc.[Team]
		,cs.[Channel Code]
		,cs.[Media Code]


	union all

	select 
		 convert(date,cle.[Date and Time]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,0 [Open Sales Orders]
		,0 [Open Return Orders]
		,0 [Scanned Orders]
        ,0 [Outbound Orders]
		,0 [50% off New Item]
		,sum(case
			when [Table No_] = 18 and [Field No_] = 102 and len(cle.[Old Value]) = 0 and len([New Value]) > 0 then 1 
			else 0
		 end) [Email Captured]
		,sum(case
			when [Table No_] = 18 and [Field No_] = 102 and len(cle.[Old Value]) > 0 and len([New Value]) = 0 then 1 
			else 0
		 end) [Email Deleted]
		,sum(case
			when [Table No_] = 18 and [Field No_] = 102 and len(cle.[Old Value]) > 0 and len([New Value]) > 0 then 1 
			else 0
		 end) [Email Modified]
		 ,sum(case
				when [Table No_] = 50011 and [Field No_] = 20 and len(cle.[Old Value]) = 0 and len([New Value]) > 0 then 1 
		 else 0
		 end) [S&S Set Up]
		,0 [Alternative Quantity]
		,0 [UpSell Quantity]
		,0 [CrossSell Quantity]
		,0 [Email Opt Ins]
		,0 [Email Opt Outs]
		,0 [Mail Opt Ins]
		,0 [Phone Opt Ins]
		,0 [Basket Increase]
		,0 [PI Conversion]
		,0 [S&S Rescue]
	from
		[dbo].[UK$Change Log Entry] cle
	join
		[ext].[CC_Team_Members] cc
	on
		(
			cle.[User ID] = cc.[User ID]
		)
	where
		[Table No_] in (18,50011)
	and [Field No_] in (102,20)
	and [Date and Time] >= dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))
	group by
		 convert(date,cle.[Date and Time])
		,cc.[User Name]
		,cc.[Team]


	union all


	select
		 convert(date,sh.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,0 [Open Sales Orders]
		,0 [Open Return Orders]
		,0 [Scanned Orders]
        ,0 [Outbound Orders]
		,0 [50% off New Item]
		,0 [Email Captured]
		,0 [Email Deleted]
		,0 [Email Modified]
		,0 [S&S Set Up]
		,sum(case
			when [Line Type] = 1 then [Quantity]
			else 0
		 end) [Alternative Quantity]
		,sum(case
			when [Line Type] = 2 then [Quantity]
			else 0
		 end) [UpSell Quantity]
		,sum(case
			when [Line Type] = 3 then [Quantity]
			else 0
		 end) [CrossSell Quantity]
		,0 [Email Opt Ins]
		,0 [Email Opt Outs]
		,0 [Mail Opt Ins]
		,0 [Phone Opt Ins]
		,0 [Basket Increase]
		,0 [PI Conversion]
		,0 [S&S Rescue]
	from 
		[dbo].[UK$Sales Header] sh
	join
		[dbo].[UK$Sales Line] sl
	on
		(
			sh.[No_] = sl.[Document No_]
		and sh.[Document Type] = sl.[Document Type]
		)
	join
		[ext].[CC_Team_Members] cc
	on
		(
			sh.[Created by] = cc.[User ID]
		)
	where
		sh.[Document Type] = 1
	and sh.[Sales Order Status] = 1
	and sh.[Order Date] >= dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))
	and sl.[Line Type] > 0
	group by
		 convert(date,sh.[Order Date])
		,cc.[User Name]
		,cc.[Team]

	union all

	select
		 convert(date,cs.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,0 [Open Sales Orders]
		,0 [Open Return Orders]
		,0 [Scanned Orders]
        ,0 [Outbound Orders]
		,0 [50% off New Item]
		,0 [Email Captured]
		,0 [Email Deleted]
		,0 [Email Modified]
		,0 [S&S Set Up]
		,sum(case
			when [Line Type] = 1 then [Quantity]
			else 0
		 end) [Alternative Quantity]
		,sum(case
			when [Line Type] = 2 then [Quantity]
			else 0
		 end) [UpSell Quantity]
		,sum(case
			when [Line Type] = 3 then [Quantity]
			else 0
		 end) [CrossSell Quantity]
		,0 [Email Opt Ins]
		,0 [Email Opt Outs]
		,0 [Mail Opt Ins]
		,0 [Phone Opt Ins]
		,0 [Basket Increase]
		,0 [PI Conversion]
		,0 [S&S Rescue]
	from 
		[ext].[CC_Sales] cs
	join
		[ext].[CC_Team_Members] cc
	on
		(
			cs.[Order Created by] = cc.[User ID]
		)
	where
		cs.[Line Type] > 0
	group by
		 convert(date,cs.[Order Date])
		,cc.[User Name]
		,cc.[Team]	

	union all

	select
		 convert(date,cpl.[Modified DateTime]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,0 [Open Sales Orders]
		,0 [Open Return Orders]
		,0 [Scanned Orders]
        ,0 [Outbound Orders]
		,0 [50% off New Item]
		,0 [Email Captured]
		,0 [Email Deleted]
		,0 [Email Modified]
		,0 [S&S Set Up]
		,0 [Alternative Quantity]
		,0 [UpSell Quantity]
		,0 [CrossSell Quantity]
		,case
			when cpl.[Record Code] = 'EMAIL' and cpl.[Status] = 0 then count(distinct(cpl.[Customer No_]))
			else 0
		 end [Email Opt Ins]
		,case				
			when cpl.[Record Code] = 'EMAIL' and cpl.[Status] = 1 then count(distinct(cpl.[Customer No_]))
			else 0
		 end [Email Opt Outs]
		,case
			when cpl.[Record Code] = 'MAIL' and cpl.[Status] = 0 then count(distinct(cpl.[Customer No_]))
			else 0
		 end [Mail Opt Ins]
		,case
			when cpl.[Record Code] = 'TEL' and cpl.[Status] = 0 then count(distinct(cpl.[Customer No_]))
			else 0
		 end [Phone Opt Ins]
		 ,0 [Basket Increase]
		 ,0 [PI Conversion]
		 ,0 [S&S Rescue]
	from
		[dbo].[UK$Customer Preferences Log] cpl
	join
		[ext].[CC_Team_Members] cc
	on
		(
			cpl.[Modified By] = cc.[User ID]
		)
	where
		[Record Type] = 0
	and
		(
			(cpl.[Record Code] = 'EMAIL')
		or
			(cpl.[Record Code] = 'TEL' and cpl.[Status] = 0)
		or
			(cpl.[Record Code] = 'MAIL' and cpl.[Status] = 0)
		)
	and [Modified DateTime] >= dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))
	group by
		 convert(date,cpl.[Modified DateTime])
		,cc.[User Name]
		,cc.[Team]
		,cpl.[Record Code]
		,cpl.[Status]

	union all

	select
		 convert(date,[Created DateTime]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,0 [Open Sales Orders]
		,0 [Open Return Orders]
		,0 [Scanned Orders]
        ,0 [Outbound Orders]
		,0 [50% off New Item]
		,0 [Email Captured]
		,0 [Email Deleted]
		,0 [Email Modified]
		,0 [S&S Set Up]
		,0 [Alternative Quantity]
		,0 [UpSell Quantity]
		,0 [CrossSell Quantity]
		,0 [Email Opt Ins]
		,0 [Email Opt Outs]
		,0 [Mail Opt Ins]
		,0 [Phone Opt Ins]
		,case
			when ile.[Reason Code] = 'GENBASK' then count(ile.[Customer No_]) else 0
		 end [Basket Increase]
		,case
			when ile.[Reason Code] = 'GENSAL' then count(ile.[Customer No_]) else 0
		 end [PI Conversion]
		,case
			when ile.[Reason Code] = 'SASRESC' then count(ile.[Customer No_]) else 0
		 end[S&S Rescue]
	from
		[dbo].[UK$Interaction Log Entry] ile
	join
		[ext].[CC_Team_Members] cc
	on
		(
			ile.[User ID] = cc.[User ID]
		)
	where
		[Interaction Template Code] = 'AGENMON'  /*in('ADMIN','AGENMON')*/
	and [Category Code] in  ('GENACT','SASACT')
	and [Reason Code] in ('GENBASK','GENSAL','SASRESC')
	and ile.[Created DateTime] >= dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))
	group by
		 convert(date,[Created DateTime]) 
		,cc.[User Name]
		,cc.[Team]
		,ile.[Reason Code]
	
	union all

	select 
		 convert(date,sh.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,case
			when sh.[Document Type] = 1 then count(sh.[No_]) else 0
		 end [Open Sales Orders]
		,case
			when sh.[Document Type] = 5 then count(sh.[No_]) else 0
		 end [Open Return Orders]
		,0 [Scanned Orders]
        ,0 [Outbound Orders]
		,0 [50% off New Item]
		,0 [Email Captured]
		,0 [Email Deleted]
		,0 [Email Modified]
		,0 [S&S Set Up]
		,0 [Alternative Quantity]
		,0 [UpSell Quantity]
		,0 [CrossSell Quantity]
		,0 [Email Opt Ins]
		,0 [Email Opt Outs]
		,0 [Mail Opt Ins]
		,0 [Phone Opt Ins]
		,0 [Basket Increase]
		,0 [PI Conversion]
		,0 [S&S Rescue]
	from 
		[dbo].[UK$Sales Header] sh
	join
		[ext].[CC_Team_Members] cc
	on
		(
			sh.[Created by] = cc.[User ID]
		)
	where
		sh.[Document Type] in (1,5)
	and sh.[Sales Order Status] = 0
	--and sh.[Order Date] >= dateadd(wk,-13,dateadd(day,1-datepart(weekday,getutcdate()),datediff(dd,0,getutcdate())))
	group by
		 convert(date,sh.[Order Date])
		,cc.[User Name]
		,cc.[Team]
		,sh.[Document Type]
/*
with x0 as
(
	select
		 convert(date,sh.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,count(sh.[No_]) [Scanned Orders]
	from 
		[dbo].[UK$Sales Header] sh
	join
		[ext].[CC_Team_Members] cc
	on
		(
			sh.[Created by] = cc.[User ID]
		)
	where
		sh.[Document Type] = 1
	and sh.[Sales Order Status] = 1
	and sh.[Order Date] >= datefromparts(year(getdate()),month(getdate())-2,1)
	and sh.[Channel Code] = 'SCAN'
	group by
		 convert(date,sh.[Order Date])
		,cc.[User Name]
		,cc.[Team]

	union all

	select
		 convert(date,cs.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,count(distinct(cs.[No_])) [Scanned Orders]
	from 
		[ext].[CC_Sales] cs
	join
		[ext].[CC_Team_Members] cc
	on
		(
			cs.[Order Created by] = cc.[User ID]
		)
	where
		cs.[Channel Code] = 'SCAN'
	group by
		 convert(date,cs.[Order Date])
		,cc.[User Name]
		,cc.[Team]
)

,x1 as
(
	select 
		 convert(date,cle.[Date and Time]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,sum(case
			when [Table No_] = 18 and [Field No_] = 102 and len(cle.[Old Value]) = 0 and len([New Value]) > 0 then 1 
			else 0
		 end) [Email Captured]
		,sum(case
			when [Table No_] = 18 and [Field No_] = 102 and len(cle.[Old Value]) > 0 and len([New Value]) = 0 then 1 
			else 0
		 end) [Email Deleted]
		,sum(case
			when [Table No_] = 18 and [Field No_] = 102 and len(cle.[Old Value]) > 0 and len([New Value]) > 0 then 1 
			else 0
		 end) [Email Modified]
		 ,sum(case
				when [Table No_] = 50011 and [Field No_] = 20 and len(cle.[Old Value]) = 0 and len([New Value]) > 0 then 1 
		else 0
		end) [S&S Set Up]
	from
		[dbo].[UK$Change Log Entry] cle
	join
		[ext].[CC_Team_Members] cc
	on
		(
			cle.[User ID] = cc.[User ID]
		)
	where
		[Table No_] in (18,50011)
	and [Field No_] in (102,20)
	and [Date and Time] >= datefromparts(year(getdate()),month(getdate())-2,1)
	group by
		 convert(date,cle.[Date and Time])
		,cc.[User Name]
		,cc.[Team]
)

,x2 as
(
	select
		 convert(date,sh.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,sum(case
			when [Line Type] = 1 then [Quantity]
			else 0
		 end) [Alternative Quantity]
		,sum(case
			when [Line Type] = 2 then [Quantity]
			else 0
		 end) [UpSell Quantity]
		,sum(case
			when [Line Type] = 3 then [Quantity]
			else 0
		 end) [CrossSell Quantity]
	from 
		[dbo].[UK$Sales Header] sh
	join
		[dbo].[UK$Sales Line] sl
	on
		(
			sh.[No_] = sl.[Document No_]
		and sh.[Document Type] = sl.[Document Type]
		)
	join
		[ext].[CC_Team_Members] cc
	on
		(
			sh.[Created by] = cc.[User ID]
		)
	where
		sh.[Document Type] = 1
	and sh.[Sales Order Status] = 1
	and sh.[Order Date] >= datefromparts(year(getdate()),month(getdate())-2,1)
	and sl.[Line Type] > 0
	group by
		 convert(date,sh.[Order Date])
		,cc.[User Name]
		,cc.[Team]

	union all


	select
		 convert(date,cs.[Order Date]) [Date]
		,cc.[User Name]
		,cc.[Team]
		,sum(case
			when [Line Type] = 1 then [Quantity]
			else 0
		 end) [Alternative Quantity]
		,sum(case
			when [Line Type] = 2 then [Quantity]
			else 0
		 end) [UpSell Quantity]
		,sum(case
			when [Line Type] = 3 then [Quantity]
			else 0
		 end) [CrossSell Quantity]
	from 
		[ext].[CC_Sales] cs
	join
		[ext].[CC_Team_Members] cc
	on
		(
			cs.[Order Created by] = cc.[User ID]
		)
	where
		cs.[Line Type] > 0
	group by
		 convert(date,cs.[Order Date])
		,cc.[User Name]
		,cc.[Team]	
)

,x3 as
(
select
	 convert(date,cpl.[Modified DateTime]) [Date]
	,cpl.[Modified By]
	,cc.[User Name]
	,cc.[Team]
	,case
		when cpl.[Record Code] = 'EMAIL' and cpl.[Status] = 0 then count(distinct(cpl.[Customer No_]))
		else 0
	 end [Email Opt Ins]
	,case
		when cpl.[Record Code] = 'EMAIL' and cpl.[Status] = 1 then count(distinct(cpl.[Customer No_]))
		else 0
	 end [Email Opt Outs]
	,case
		when cpl.[Record Code] = 'MAIL' and cpl.[Status] = 0 then count(distinct(cpl.[Customer No_]))
		else 0
	 end [Mail Opt Ins]
	,case
		when cpl.[Record Code] = 'TEL' and cpl.[Status] = 0 then count(distinct(cpl.[Customer No_]))
		else 0
	 end [Phone Opt Ins]
from
	[dbo].[UK$Customer Preferences Log] cpl
join
	[ext].[CC_Team_Members] cc
on
	(
		cpl.[Modified By] = cc.[User ID]
	)
where
	[Record Type] = 0
and
	(
		(cpl.[Record Code] = 'EMAIL')
	or
		(cpl.[Record Code] = 'TEL' and cpl.[Status] = 0)
	or
		(cpl.[Record Code] = 'MAIL' and cpl.[Status] = 0)
	)
and [Modified DateTime] >= datefromparts(year(getdate()),month(getdate())-2,1)
group by
	 convert(date,cpl.[Modified DateTime])
	,cpl.[Modified By]
	,cc.[User Name]
	,cc.[Team]
	,cpl.[Record Code]
	,cpl.[Status]
)


select
	 w.[Date]
	,w.[User Name]
	,w.[Team]
	,w.[Scanned Orders]
	,w.[Email Captured]
	,w.[Email Deleted]
	,w.[Email Modified]
	,w.[S&S Set Up]
	,w.[Alternative Quantity]
	,w.[UpSell Quantity]
	,w.[CrossSell Quantity]
	,w.[Email Opt Ins]
	,w.[Email Opt Outs]
	,w.[Mail Opt Ins]
	,w.[Phone Opt Ins]
from
	(
	select
		 coalesce(x0.[Date],x1.[Date],x2.[Date],x3.[Date]) [Date]
		,coalesce(x0.[User Name],x1.[User Name],x2.[User Name],x3.[User Name]) [User Name]
		,coalesce(x0.[Team],x1.[Team],x2.[Team],x3.[Team]) [Team]
		,isnull(x0.[Scanned Orders],0) [Scanned Orders]
		,isnull(x1.[Email Captured],0) [Email Captured]
		,isnull(x1.[Email Deleted],0) [Email Deleted]
		,isnull(x1.[Email Modified],0) [Email Modified]
		,isnull(x1.[S&S Set Up],0) [S&S Set Up]
		,isnull(x2.[Alternative Quantity],0) [Alternative Quantity]
		,isnull(x2.[UpSell Quantity],0) [UpSell Quantity]
		,isnull(x2.[CrossSell Quantity],0) [CrossSell Quantity]
		,isnull(x3.[Email Opt Ins],0) [Email Opt Ins]
		,isnull(x3.[Email Opt Outs],0) [Email Opt Outs]
		,isnull(x3.[Mail Opt Ins],0) [Mail Opt Ins]
		,isnull(x3.[Phone Opt Ins],0) [Phone Opt Ins]
	from
		x0
	full outer join
		x1
	on
		(
			x0.[Date] = x1.[Date]
		and x0.[User Name] = x1.[User Name]
		and x0.[Team] = x1.[Team]
		)
	full outer join
		x2
	on
		(
			isnull(x0.[Date],x1.[Date]) = x2.[Date]
		and isnull(x0.[User Name],x1.[User Name]) = x2.[User Name]
		and isnull(x0.[Team],x1.[Team]) = x2.[Team]
		)
	full outer join
		x3
	on
		(
			coalesce(x0.[Date],x1.[Date],x2.[Date]) = x3.[Date]
		and coalesce(x0.[User Name],x1.[User Name],x2.[User Name]) = x3.[User Name]
		and coalesce(x0.[Team],x1.[Team],x2.[Team]) = x3.[Team]
		)
	) w
*/
GO

GRANT SELECT
    ON OBJECT::[ext].[CC_Team_Reporting] TO [All CompanyX Staff]
    AS [dbo];
GO
