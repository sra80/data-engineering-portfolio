CREATE view ext.email_subscriptions_due

as

--adopted from C34_SubscriptionsDue

with s as
	(select
		 sl.[Next Delivery Date] ndd
		,sum(1) sub_count
	from
		[UK$Subscriptions Line] sl
	where
		sl.[Status] = 0 
	and sl.[Next Delivery Date] >= dateadd(day,1,convert(date,getdate())) 
	and sl.[Next Delivery Date] <= dateadd(day,3,convert(date,getdate()))
	group by
		sl.[Next Delivery Date]
	)

select 
	  case datediff(day,getdate(),ndd) 
		when 1 then format(ndd,'"Tomorrow" (dd/MM/yyyy)')
		when 2 then format(ndd,'"Day After Tomorrow" (dd/MM/yyyy)')
		when 3 then format(ndd,'"In 3 Days Time" (dd/MM/yyyy)')
	 end [Despatch Date]
	,format(sub_count,'###,###,##0') [Subscriptions]
	,rank() over (order by ndd) r
from
	s
GO
