
CREATE procedure [ext].[sp_FullPrices]

	(

		@sku nvarchar(32)
	)

as

set nocount on

declare @getdate date = dateadd(day,-2,getdate())

declare @period int = convert(int,format(@getdate,'yyyyMMdd'))

--declare @c table ([Item No_] nvarchar(32), [Starting Date] date, [Ending Date] date, [Unit Price] decimal )

;with c as
(
select
	 [Item No_]
	,[Starting Date] 
	,[Ending Date]
	,[Unit Price]
from
	[dbo].[UK$Sales Price] sp
where
	sp.[Sales Code] = 'FULLPRICES' 
and sp.[Item No_] = @sku --'5HTP060' --


union all


select
	 [Item No_]
	,[Starting Date]+1 
	,[Ending Date]
	,[Unit Price]
from
	c
where
	[Starting Date] < [Ending Date]
and [Starting Date] <= @getdate --dateadd(day,-1,convert(date,getdate()))
--and c.[Item No_] = @sku--'5HTP060' --
)

insert into [ext].[FullPrices] ([keyItemNo], [Price Date], [Unit Price])
select
	 [Item No_]
	,[Starting Date] [Price Date]
	,[Unit Price]
from c
order by
	[Starting Date]
option (MAXRECURSION 10000)
GO
