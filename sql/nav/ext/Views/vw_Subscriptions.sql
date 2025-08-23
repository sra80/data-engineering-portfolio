SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  or alter view [ext].[vw_Subscriptions]

as

select 
    c.[Company],
    h.No_ [Subscription No],
    db_sys.fn_Lookup('UK$Subscriptions Header','Status',h.[Status]) [Status],
    h.[Customer No_] [Customer No],
    convert(date,h.[Created Date]) [Created Date],
    nullif(convert(date,[Cancelled Date]),datefromparts(1753,1,1)) [Cancelled Date],
    cancel.[Description] [Cancel Reason],
    h.[Original Order No_] [Original Order No],
	isnull(nullif(left(h.[Original Order No_],abs(patindex('%[^A-Z]%',h.[Original Order No_])-1)),''),'SO') [Order Prefix],
	isnull(nullif(h.[Channel Code],''),'PHONE') [Channel Code],
	p.[Platform],
    nullif(h.[Media Code],'') [Media Code],
    mc.[Description] [Media Code Description],
    l.[Item No_] [Item No],
    i.[Description] [Item Description],
    convert(int,l.Quantity) [Quantity],
    convert(date,l.[Starting Date]) [Start Date],
    nullif(convert(date,l.[Ending Date]),datefromparts(1753,1,1)) [End Date],
    try_convert(int,[Frequency (No_ of Days)]) [Frequency],
    l.[Next Delivery Date],
    nullif(convert(date,l.[Last S&S Order Creation Date]),datefromparts(1753,1,1)) [Last Repeat Order Creation Date],
	(select count([Subscription No_]) from [dbo].[UK$Item Ledger Entry] ile where ile.[Subscription No_] = h.[No_] and patindex('ZZ%',[Item No_]) = 1) [Repeat Deliveries],
    i.[Range Code]
from
    [hs_consolidated].[Subscriptions Header] h--[dbo].[UK$Subscriptions Header] h
cross apply
    (
        select top 1 * from [hs_consolidated].[Subscriptions Line] l/*[dbo].[UK$Subscriptions Line] l*/ where h.[company_id] = l.[company_id] and h.[No_] = l.[Subscription No_] order by l.[Line No_] desc
    ) l
join
    [hs_consolidated].[Item] i--[dbo].[UK$Item] i
on
    (
        l.[company_id] = i.[company_id]
    and l.[Item No_] = i.No_
    )
left join
    [hs_consolidated].[Subscr_ Canc_ Reason Code] cancel--[dbo].[UK$Subscr_ Canc_ Reason Code] cancel
on
    (
        h.company_id = cancel.company_id
    and h.[Cancel Reason] = cancel.Code
    )
left join
    [hs_consolidated].[Media Code] mc--[dbo].[UK$Media Code] mc
on
    (
        h.[company_id] = mc.[company_id]
    and h.[Media Code] = mc.Code
    )
left join
	(
		select 
			ps.Order_Prefix,
			ps.[Channel_Code],
			p.[Platform],
            ps.[company_id]
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
			p.[Platform],
            ps.[company_id]
	) p
on
	(
        p.company_id = h.[company_id]
	and	isnull(nullif(left(h.[Original Order No_],abs(patindex('%[^A-Z]%',h.[Original Order No_])-1)),''),'SO') = p.Order_Prefix
	and isnull(nullif(h.[Channel Code],''),'PHONE') = p.[Channel_Code]
	)
join
    [db_sys].[Company] c
on
    (
        h.[company_id] = c.[ID]
    )
--where
--	h.[Created Date] >= datefromparts(year(dateadd(month,-1,getdate()))-4,1,1)
GO