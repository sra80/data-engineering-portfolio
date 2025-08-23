


CREATE procedure [ext].[sp_SS_Payment_Attempts]

as


truncate table [ext].[SS_Payment_Attempts]

;with x as
(
	select 
		 [No_]
		,[Sell-to Customer No_]
		,[Order Date]
		,[External Document No_]
		,[Subscription No_]
		,[Created by]
	from
		[NAV_PROD_REPL].[dbo].[UK$Sales Header] sh
	where
		[Channel Code] = 'REPEAT'
	and len([Subscription No_]) > 0

	union all

	select 
		 [No_]
		,[Sell-to Customer No_]
		,[Order Date]
		,[External Document No_]
		,[Subscription No_]
		,[Order Created by]
	from
		[NAV_PROD_REPL].[dbo].[UK$Sales Header Archive] sha 
	where
		[Archive Reason] in (1,3)
	and [Channel Code] = 'REPEAT'
	and len([Subscription No_]) > 0
)

insert into [ext].[SS_Payment_Attempts] ([Attempt ID],[External Document No],[Attempt],[Processing Status],[Error],[Attempt Date],[Subscription],[Customer])
select
		pr.[ID] [Attempt ID]
	,x.[External Document No_] [External Document No]
	,case
		when row_number() over (partition by pr.[Buying Reference No_] order by pr.[ID]) = 1 then '1st Attempt'
		when row_number() over (partition by pr.[Buying Reference No_] order by pr.[ID]) = 2 then '2nd Attempt'
		when row_number() over (partition by pr.[Buying Reference No_] order by pr.[ID]) = 3 then '3rd Attempt'
		when row_number() over (partition by pr.[Buying Reference No_] order by pr.[ID]) = 4 then '4th Attempt'
		end as [Attempt]
	,case	
		when pr.[Processing Status] = 5 then 'Success'
		when pr.[Processing Status] = 6 then 'Failure'
		end [Processing Status]
	,ml.[Message Text] [Error]
	,pr.[Payment Date] [Attempt Date]
	,x.[Subscription No_] [Subscription]
	,pr.[Customer No_] [Customer]
from
	[NAV_PROD_REPL].[dbo].[UK$Payment_Refund] pr 
join
	x
on
	(
		pr.[Type] = 3
	and x.[Sell-to Customer No_] = pr.[Customer No_]
	and x.[External Document No_] = pr.[Buying Reference No_]
	)
left join
	[NAV_PROD_REPL].[dbo].[UK$Message Log] ml 
on
	(
		pr.[Processing Message Log ID] = ml.[ID]
	)
where
	pr.[Payment Date]  > dateadd(month,-6, convert(date,getdate())) --6 months
and pr.[Processing Status] in (5,6)
GO
