create or alter view ext.vw_Sales_Price_Overlap_IE

as

select 
	 a.[Sales Code]
	,a.[Sales Type]
	,a.[Item No_] [SKU]
	,convert(int,round(a.[Minimum Quantity],2)) [Minimum Quantity]
	,convert(nvarchar,a.[Starting Date],103) [Starting Date]
	,convert(nvarchar,a.[Ending Date],103) [Ending Date]
	,format(a.[Unit Price],'c', 'en-IE') [Unit Price]
	,case when dense_rank() over (order by a.[Sales Code], a.[Sales Type], a.[Item No_])%2 = 0 then '#D9E1F2' else '#FFFFFF' end bg
from 
	dbo.[IE$Sales Price] a
cross apply
	(
	select c = count(1)
	from dbo.[IE$Sales Price] b
	where a.[Item No_] = b.[Item No_] and a.[Sales Code] = b.[Sales Code] and a.[Sales Type] = b.[Sales Type] and a.[Minimum Quantity] = b.[Minimum Quantity] and a.[Starting Date] < b.[Ending Date] and a.[Ending Date] > b.[Starting Date]
	having count(1) > 1
	) b