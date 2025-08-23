CREATE view [ext].[OKR_TeamDelight]

as

with x as
(
select
	 0 [period] 
	,(95/convert(decimal,[All Complaints])) [S&S Complaints]
	,0 [S&S Cancellations]
from
	(
		select 
			sum(1) [All Complaints]
		from
			[dbo].[UK$Interaction Log Entry]
	where
		[Interaction Template Code] = 'COMPLAINT'
	and convert(date,[Created DateTime]) > '20230625'
	and convert(date,[Created DateTime]) < '20230926'
	) x

union all

select
	 1 [period] 
	,([S&S Complaints]/convert(decimal,[All Complaints])) [S&S Complaints]
	,0 [S&S Cancellations]
from
	(select 
		sum(1) [S&S Complaints]
	from
		[dbo].[UK$Interaction Log Entry]
	where
		[Interaction Template Code] = 'COMPLAINT'
	and [Reason Code] in ('DELLAT','DELSSE','OFFSSPRED','OFFSSSIGN','PRISAS','PROSSOOS','WEBDEF','WEBNXT','WEBSASC','WEBSASF','WEBSASU')
	and convert(date,[Created DateTime]) > convert(date,dateadd(month,-3,getdate()))
	and convert(date,[Created DateTime]) < convert(date,dateadd(day,-1,getdate()))
	) x
cross apply
	(
	select 
		sum(1) [All Complaints]
	from
		[dbo].[UK$Interaction Log Entry]
	where
		[Interaction Template Code] = 'COMPLAINT'
	and convert(date,[Created DateTime]) > convert(date,dateadd(month,-3,getdate()))
	and convert(date,[Created DateTime]) < convert(date,dateadd(day,-1,getdate()))
	) y
)


,y as
(
	select
		 0 [period] 
		,0 [S&S Complaints]
		,([S&S Cancellations After 1st Repeat]/convert(decimal,[S&S Cancellations])) [S&S Cancellations]
	from
		(
		select
			sum(1) [S&S Cancellations After 1st Repeat]
		from
			(
				select 
					 sha.[Subscription No_]
					,sum(1) [Repeats]
				from
					[dbo].[UK$Sales Header Archive] sha
				where
					sha.[Archive Reason] = 3
				group by
					sha.[Subscription No_]
			) sha
		join
			(
				select
					[No_]
				from
					[NAV_PROD_REPL].[dbo].[UK$Subscriptions Header]
				where
					[Status] = 2
				and [Cancelled Date] > '20230625'
				and [Cancelled Date] < '20230926'
			) sh
		on
			(
				sh.[No_] = sha.[Subscription No_]
			and sha.[Repeats] = 1
			)
		) x
cross apply
	(
		select
			sum(1) [S&S Cancellations]
		from
			[NAV_PROD_REPL].[dbo].[UK$Subscriptions Header]
		where
			[Status] = 2
		and [Cancelled Date] > '20230625'
		and [Cancelled Date] < '20230926'
	) y

	union all

	select
		 1 [period] 
		,0 [S&S Complaints]
		,([S&S Cancellations After 1st Repeat]/convert(decimal,[S&S Cancellations])) [S&S Cancellations]
	from
		(
		select
			sum(1) [S&S Cancellations After 1st Repeat]
		from
			(
				select 
					 sha.[Subscription No_]
					,sum(1) [Repeats]
				from
					[dbo].[UK$Sales Header Archive] sha
				where
					sha.[Archive Reason] = 3
				group by
					sha.[Subscription No_]
			) sha
		join
			(
				select
					[No_]
				from
					[NAV_PROD_REPL].[dbo].[UK$Subscriptions Header]
				where
					[Status] = 2
				and [Cancelled Date] > convert(date,dateadd(month,-3,getdate()))
			) sh
		on
			(
				sh.[No_] = sha.[Subscription No_]
			and sha.[Repeats] = 1
			)
		) x
	cross apply
		(
			select
				sum(1) [S&S Cancellations]
			from
				[NAV_PROD_REPL].[dbo].[UK$Subscriptions Header]
			where
				[Status] = 2
			and [Cancelled Date] > convert(date,dateadd(month,-3,getdate()))
		) y
) 

select
	*
from
	x
union all
select
	*
from
	y


--select 
--	case
--		when x.[period] = 0 then x.[S&S Complaints] else 0 
--	end [0_S&S Complaints],
--	case
--		when x.[period] = 1 then x.[S&S Complaints] else 0
--	end [1_S&S Complaints],
--	[0_S&S Cancellations],
--	[1_S&S Cancellations]
--from
--	x
--cross apply
--	(
--		select 
--			case
--			when y.[period] = 0 then y.[S&S Cancellations] else 0 
--		end [0_S&S Cancellations],
--		case
--			when y.[period] = 1 then y.[S&S Cancellations]else 0
--		end [1_S&S Cancellations]
--		from
--			y
--	) y
GO

GRANT SELECT
    ON OBJECT::[ext].[OKR_TeamDelight] TO [All CompanyX Staff]
    AS [dbo];
GO
