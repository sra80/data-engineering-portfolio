




CREATE or ALTER view [ext].[NonCapturedOrders]

as

select		
	sh.[Order Date],
	sh.[No_] [Order No],		
	sh.[On Hold],	
	pr1.[Payment Reference No_] [Payment Reference No],
	--sh.[External Document No_] [External Document No],
	--l.[_value] [Processing Status],
	sh.[Channel Code],
	sl.[Subscription No_] [Subscription No],
	db_sys.fn_Lookup('Subscriptions Header','Status',s.[Status]) [Subscription Status] --l.[_value] [Subscription Status]
from		
	[dbo].[UK$Sales Header] sh	
join
	[dbo].[UK$Sales Line] sl
on
	(
		sh.[No_] = sl.[Document No_]
	)
join		
	(select distinct	
		pr.[Buying Reference No_],
		pr.[Processing Status],
		pr.[Payment Reference No_]
	from	
		[dbo].[UK$Payment_Refund] pr 
	where 	
		pr.[Type] = 2
	--and pr.[Processing Status] = 5
	and pr.[Payment Method Code] = 'CREDITCARD'	
		
	) pr1	
on		
	(	
		sh.[External Document No_] = pr1.[Buying Reference No_]
	)	
--join
--	[db_sys].[Lookup] l
--on
--	(
--		l.[tableName] ='UK$Payment_Refund'
--	and l.columnName = 'Processing Status'
--	and pr1.[Processing Status] = l._key
--	)
left join
	[dbo].[UK$Subscriptions Header] s
on
	(
		s.[No_] = sl.[Subscription No_]
	)
left join
	db_sys.Lookup l
on
	(
		l.[tableName] = 'UK$Subscriptions Header'
	and l.columnName = 'Status'
	and l.[_key] = s.[Status]
	)
left join		
	(select	
		pr.[Buying Reference No_]
	from	
		[dbo].[UK$Payment_Refund] pr 
	where 	
		pr.[Type] = 3
	and pr.[Payment Method Code] = 'CREDITCARD'	
	) pr2	
on		
	(	
		sh.[External Document No_] = pr2.[Buying Reference No_]
		
	)	
where		
	sh.[Sales Order Status] = 0
and sh.[On Hold] <> 'OQY'
and sh.[Document Type] = 1		
and pr2.[Buying Reference No_] is null		
--and sh.[No_] = 'SO-11250375'
GO

GRANT SELECT
    ON OBJECT::[ext].[NonCapturedOrders] TO [All CompanyX Staff]
    AS [dbo];
GO
