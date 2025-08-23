





CREATE view [ext].[CC_OOS_Orders]

as

select  
	sh.[Channel Code]
   ,sh.[Sell-to Customer No_] [Customer]
   ,sh.[Sell-to Customer Name] [Name]
   ,sh.[Sell-to Customer Name 2] [Name 2]
   ,sh.[Sell-to Address] [Address]
   ,sh.[Sell-to Address 2] [Address 2]
   ,sh.[Sell-to Country_Region Code] [Country/Region Code]
   ,sh.[Sell-to City] [City]
   ,sh.[Sell-to County] [County]
   ,sh.[Sell-to Post Code] [Post Code]
   ,sl.[Document No_] [Order No]
   ,sl.[No_] [Item]
   ,sl.[Description] [Item Description]
   ,sl.[Outstanding Quantity]
   ,case
		when i.[Status] = 0 then 'Prelaunch'
		when i.[Status] = 1 then 'Active'
		when i.[Status] = 2 then 'Discontinued'
		when i.[Status] = 3 then 'Obsolete'
		when i.[Status] = 4 then 'Run Down'
	else 'Unspecified'
	end [Product Status]
   ,case when ile.[Entry No_] is null then 'No' else 'Yes' end [OOS Letter Sent]
	--,ile.[Created DateTime]
   --,os.[Available Quantity] [Available Stock]
from
	[dbo].[UK$Sales Line] sl (nolock)
join  
	[dbo].[UK$Sales Header] sh (nolock)
on
	(
		sh.[Document Type] = sl.[Document Type]
	and sh.[No_] = sl.[Document No_]
	)
left join
	(
		select
			 max([Timestamp Date Time]) [Date]
			,[Item No_]
			,[Available Quantity]
		from	
			[dbo].[UK$Outbound Stock]
		where
			[Integration Code] = 'TRADEIT-UK'
		group by
			[Item No_]
			,[Available Quantity]
	) os
on
	sl.[No_] = os.[Item No_]
join
	[dbo].[UK$Item] i
on
	(
		sl.[No_] = i.[No_]
	)
left join
	[dbo].[UK$Interaction Log Entry] ile
on
	(
		ile.[Sales Order No_] = sl.[Document No_]
	and ile.[Item No_] = sl.[No_]
	and ile.[Created DateTime] >= sh.[Order Date]
	and ile.[Interaction Template Code] = 'ADMIN'
	and ile.[Category Code] = 'CUSTSERV'
	and ile.[Reason Code] = 'OOSLETTER'
	)
where
	sh.[Document Type] = 1
and	sl.[Outstanding Quantity] <> 0
and sh.[Channel Code] in ('SCAN','MAIL')
and sl.[Gen_ Prod_ Posting Group] = 'ITEM'
and 
	(
	 os.[Available Quantity] = 0
		or
	 os.[Available Quantity] is null
	 )
GO

GRANT SELECT
    ON OBJECT::[ext].[CC_OOS_Orders] TO [All CompanyX Staff]
    AS [dbo];
GO
