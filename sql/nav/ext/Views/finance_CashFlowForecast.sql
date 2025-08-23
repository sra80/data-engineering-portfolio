


CREATE view [ext].[finance_CashFlowForecast]

as

--Average Forecast
with x as 
(
select 
	 [Date]
	,datepart(week,[Date]) [Week]
	,sum([Gross Sales_current]) - sum([Refunds_current]) - sum([Vouchers_current]) [Gross Revenue]
from
	[ext].[vw_budgets]
group by
	[Date]
)

,y as
(
select 
	 x.[Date]
	,x.[Week]
	,sum([Gross Revenue]) over (order by [Date] rows between 5 preceding and current row)  [Gross Revenue]
from 
	x
)

select
	 y.[Date] [Week Start Date]
	,y.[Week]
	,'Forecast' [Type]
	,'GBP' [Currency Code]
	,y.[Gross Revenue]/6 [Amount]
from
	y
where
	y.[Date] >= dateadd(wk, 0, dateadd(day,1 - datepart(weekday, getdate()), datediff(dd, 0, getdate())))
and y.[Date] <= dateadd(wk, 5, dateadd(day,1 - datepart(weekday, getdate()), datediff(dd, 0, getdate())))


union all


--Actual Credit Card Payments
select
	dateadd(week,datediff(week,-1,convert(date,[Processed Date Time])),-1) [Week Start Date]
   ,datepart(week,[Processed Date Time]) [Week]
   ,'Payments' [Type]
   ,case when [Currency Code] = '' then 'GBP' else [Currency Code] end [Currency Code]
   ,case when [Currency Code] = '' then sum([Collected Amount (LCY)]) else sum([Collected Amount]) end [Amount]
from
	[dbo].[UK$Payment_Refund]
where
	[Type] = 3
and [Processing Status] = 5
and [Processed Date Time] < dateadd(wk, 0, dateadd(day,1 - datepart(weekday, getdate()), datediff(dd, 0, getdate()))) --current week
and [Processed Date Time] >= dateadd(wk, -6, dateadd(day,1 - datepart(weekday, getdate()), datediff(dd, 0, getdate()))) --5 weeks ago
group by
	 dateadd(week,datediff(week,-1,convert(date,[Processed Date Time])),-1)
	,datepart(week,[Processed Date Time])
	,[Currency Code]
GO

GRANT SELECT
    ON OBJECT::[ext].[finance_CashFlowForecast] TO [user@example.com]
    AS [dbo];
GO
