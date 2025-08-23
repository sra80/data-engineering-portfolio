CREATE view [ext].[vw_FOD]

as


with x as
(
	select
		[Customer No_] [Customer],
		convert(date,[Created Date]) [FOD],
		isnull(nullif(left([Original Order No_],abs(patindex('%[^A-Z]%',[Original Order No_])-1)),''),'SO') [Order Prefix],
		isnull(nullif([Channel Code],''),'PHONE') [Channel],
		row_number() over(partition by [Customer No_] order by [Created Date]) r
	from	
		[NAV_PROD_REPL].[dbo].[UK$Subscriptions Header] 
)
select
	x.[Customer],
	x.[FOD],
	p.[Platform] [First Platform],
	1 [Subscriber]
from 
	x
join
	(
		select 
			ps.Order_Prefix,
			ps.[Channel_Code],
			p.[Platform]
		from
			[ext].[Platform] p
		join
			[ext].[Platform_Setup] ps
		on
			(
				p.[ID] = ps.[PlatformID]
			)
		where
			p.[Platform] not in ('Amazon','eBay')	
		group by
			ps.Order_Prefix,
			ps.[Channel_Code],
			p.[Platform]
	) p
on
	( 
		x.[Order Prefix] = p.Order_Prefix
	and x.[Channel] = p.[Channel_Code]
	)
where
	r = 1

/*
select
	[Customer No_] [Customer],
	convert(date,min([Created Date])) [FOD],
	1 [New Subscriber]
	--,p.[Platform] [First Platform)
from	
	[NAV_PROD_REPL].[dbo].[UK$Subscriptions Header]
group by
	[Customer No_]
*/
GO
