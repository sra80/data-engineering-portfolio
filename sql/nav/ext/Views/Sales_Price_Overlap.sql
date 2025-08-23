create or alter view ext.Sales_Price_Overlap

as

--adopted from [A27_salesPriceOverlap] 

select 
	a.[Sales Code],
	db_sys.fn_Lookup('Sales Price','Sales Type',a.[Sales Type]) [Sales Type],
	a.[Item No_] [SKU],
	convert(int,round(a.[Minimum Quantity],2)) [Minimum Quantity],
	convert(nvarchar,a.[Starting Date],103) [Starting Date],
	convert(nvarchar,a.[Ending Date],103) [Ending Date],
	format(a.[Unit Price],'C','en-gb') [Unit Price],
	case when dense_rank() over (order by a.[Sales Code], a.[Sales Type], a.[Item No_])%2 = 0 then '#D9E1F2' else '#FFFFFF' end bg,
	row_number() over (order by a.[Item No_], a.[Sales Code], a.[Sales Type], a.[Starting Date]) r
from 
	dbo.[UK$Sales Price] a
cross apply
	(
	select c = count(1)
	from dbo.[UK$Sales Price] b
	where a.[Item No_] = b.[Item No_] and a.[Sales Code] = b.[Sales Code] and a.[Sales Type] = b.[Sales Type] and a.[Minimum Quantity] = b.[Minimum Quantity] and a.[Starting Date] < b.[Ending Date] and a.[Ending Date] > b.[Starting Date]
	having count(1) > 1
	) b
where 
	(
		a.[Sales Code] != 'SHOP' 
	)
GO
