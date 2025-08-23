CREATE or ALTER view [ext].[ErroredSubscriptions]

as

with x as
(
select 
	 sl.[Item No_] [Item No]
	,i.[Description] [Item Description]
	,db_sys.fn_Lookup('Item','Status',i.[Status]) [Item Status]--,l.[_value] [Item Status]
	,i.[Range Code]
	,count(sh.[No_]) [Subscriptions]
	,sum(sl.[Quantity]) [Units]
from
	[dbo].[UK$Subscriptions Header] sh
join
	[dbo].[UK$Subscriptions Line] sl
on
	(
		sh.[No_] = sl.[Subscription No_]
	)
join
	[dbo].[UK$Item] i
on
	(
		i.[No_] = sl.[Item No_]
	)
-- left join
-- 	[db_sys].[Lookup] l
-- on
-- 	(
-- 		l.[columnName] = 'Status'
-- 	and l.[tableName] = 'UK$Item'
-- 	and l.[_key] = i.[Status]
-- 	)
where
	sh.[Status] = 6
and sl.[Next Delivery Date] > '17530101'
group by
	 sl.[Item No_]
	,i.[Description]
	,db_sys.fn_Lookup('Item','Status',i.[Status]) --l.[_value]
	,i.[Range Code]
) 

select
	 x.[Item No]
	,x.[Item Description]
	,x.[Item Status]
	--,sp.[Unit Price]
	,x.[Subscriptions]
	,x.[Units]
	,case
		when x.[Item Status] = 'Discontinued' 
		then 0 else x.[Units] * sp.[Unit Price] 
		end 
	 [Expected Gross Revenue]
	,case
		when ic.[Item No_] is null then 'No'
		else 'Yes'
	 end [Repeat Channel On]
	--,isnull(os.[Qty_ Ring Fenced],0) [Ring Fenced Quantity]
	--,isnull(os.[Available Quantity],0) [Available Quantity]
	,case
		when isnull(os.[Inventory Quantity],0) - isnull(os.[Qty_ on Sales Order],0) - isnull(os.[Qty_ in QC],0) - isnull(os.[Minimum Qty_],0) < 0 then 0
		else isnull(os.[Inventory Quantity],0) - isnull(os.[Qty_ on Sales Order],0) - isnull(os.[Qty_ in QC],0) - isnull(os.[Minimum Qty_],0)
	end [S&S Available Stock]
	,dateadd(day,5,db_sys.foweek(pl.[Expected Receipt Date],case when x.[Range Code] = 'ELITE' then 3 when pl.distribution_loc = 1 then 0 else 1 end)) [Next Stock In]
from
	x
left join
	[dbo].[UK$Outbound Stock] os
on
	(
		os.[Item No_] = x.[Item No]
	)
left join
	[dbo].[UK$Item Channel] ic
on
	(
		ic.[Channel Code] = 'REPEAT'
	and ic.[Item No_] = x.[Item No]
	)
left join
	(
		select 
			 sp.[Item No_]
			,sp.[Unit Price]
		from
			[dbo].[UK$Sales Price] sp
		where
			sp.[Sales Code] = 'SUBDEFAULT'
		and [Starting Date] <= getdate()
		and [Ending Date] >= getdate()
		group by
			 sp.[Item No_]
			,sp.[Unit Price]
		) sp
on
	(
		x.[Item No] = sp.[Item No_]
	)
outer apply
	(
		select top 1
			 pl.[Expected Receipt Date]
			,l0.distribution_loc
		from
			[dbo].[UK$Purchase Line] pl
		join
			[dbo].[UK$Purchase Header] ph
		on
			(
				ph.[Document Type] = pl.[Document Type]
			and ph.[No_] = pl.[Document No_]
			)
		join
			ext.Location l0
		on
			(
				l0.company_id = 1
			and pl.[Location Code] = l0.location_code
			)
		where
			    ph.[Document Type] = 1
            and ph.[Status] in (1,2)
            and ph.[Status 2] < 5
            and x.[Item No] = pl.[No_]
            and pl.[Type] = 2
            and pl.[Outstanding Quantity] > 0
            and pl.[Expected Receipt Date] >=  db_sys.foweek(getdate(),0)
		order by
			pl.[Expected Receipt Date]
		) pl
GO
