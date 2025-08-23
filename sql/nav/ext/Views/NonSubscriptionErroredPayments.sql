SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create or alter view [ext].[NonSubscriptionErroredPayments]

as

select distinct
	sh.[No_] [Order No],
	db_sys.fn_Lookup('Sales Header','Sales Order Status',sh.[Sales Order Status]) [Order Status], --l1.[_value] [Order Status],
	--pr.[Buying Reference No_],
	pr.[Payment Reference No_] [Payment Reference No],
	sh.[Channel Code],
	sh.[Order Date],
	ml.[Message Text] [Processing Error Message]
from
	[dbo].[UK$Sales Header] sh
join
	[dbo].[UK$Sales Line] sl
on
	(
		sh.[No_] = sl.[Document No_]
	)
join
	(
		select 
			max([Processing Message Log ID]) [Processing Message Log ID],
			max([Payment Reference No_]) [Payment Reference No_],
			[Buying Reference No_],
            [Processing Status]
		from	
			[dbo].[UK$Payment_Refund]
		group by
			[Buying Reference No_],
            [Processing Status]
	) pr
on
	(
		sh.[External Document No_] = pr.[Buying Reference No_]
	)
left join
	[dbo].[UK$Message Log] ml
on
	pr.[Processing Message Log ID] = ml.[ID]
where
	sh.[Sales Order Status] = 0
and sh.[Document Type] = 1
and len(sh.[On Hold])  > 0
and sh.[Channel Code] <> 'REPEAT'
and pr.[Processing Status] = 6
and ml.[Message Text] is not null
and sl.[Gen_ Prod_ Posting Group] = 'ITEM'


GO