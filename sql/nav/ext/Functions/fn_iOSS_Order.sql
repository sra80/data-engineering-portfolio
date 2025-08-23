
CREATE FUNCTION [ext].[fn_iOSS_Order]
	(
	@orderNo nvarchar(32)
	)

returns nvarchar(32)

as

begin

declare @check tinyint

select top 1
	 @check = 1
from
	[dbo].[UK$Sales Invoice Header] sih	
join
	[dbo].[UK$Sales Invoice Line] sil
on
	sil.[Document No_] = sih.[No_]
join
	[dbo].[UK$Country_Region] cr
on
	sih.[Ship-to Country_Region Code] = cr.[Code]
join
	(select
		  c.[No_]
		 ,ct.[iOSS not applicable]
	 from
		[dbo].[UK$Customer] c
	left join
		[dbo].[UK$Customer Type] ct
	on 
		c.[Customer Type] = ct.[Code]
	where
		ct.[iOSS not applicable] = 0 --iOOS Condition
	) c
on
	sih.[Sell-to Customer No_] = c.[No_]
--left join			
--	(select
--		 [Buying Reference No_]
--		,min(pr.[Payment Date]) [Payment Date]
--	 from
--		[dbo].[UK$Payment_Refund] pr
--	 where
--		pr.[Type] in (1,3)
--	 and pr.[Processing Status] = 5 --completed
--	 group by
--		[Buying Reference No_]
--	) pr
--on			
--	sih.[External Document No_] = pr.[Buying Reference No_]	
where
	sih.[Order No_]  = @orderNo 
and sih.[Order Date] >= datefromparts(2021,8,1)
--and pr.[Payment Date] >= datefromparts(2021,8,1)
and sil.[Location Code] = 'WASDSP'  --iOOS Condition
and cr.[Is iOSS] = 1 --iOOS Condition
and patindex('ZZ%',sil.[No_]) = 0
group by
	sih.[Order No_]
having
	sum(sil.[Amount Including VAT]/case when ceiling(sih.[Currency Factor]) > 0 then sih.[Currency Factor] else 1 end) < 125  --iOOS Condition


if @check is null 


select top 1
	  @check = 1
from
	[ext].[Sales_Header] sh --[dbo].[UK$Sales Header] sh
join
	[ext].[Sales_Line] sl --[dbo].[UK$Sales Line] sl 
on
	sh.[Document Type] = sl.[Document Type]
and sh.[No_] = sl.[Document No_]
join
	[dbo].[UK$Country_Region] cr
on
	sh.[Ship-to Country_Region Code] = cr.[Code]
join
	(select
		  c.[No_]
		 ,ct.[iOSS not applicable]
	 from
		[dbo].[UK$Customer] c
	left join
		[dbo].[UK$Customer Type] ct
	on 
		c.[Customer Type] = ct.[Code]
	where
		ct.[iOSS not applicable] = 0 --iOOS Condition
	) c
on
	sh.[Sell-to Customer No_] = c.[No_]
--left join			
--	(select
--		 [Buying Reference No_]
--		,min(pr.[Payment Date]) [Payment Date]
--	 from
--		[dbo].[UK$Payment_Refund] pr
--	 where
--		pr.[Type] in (1,3)
--	 and pr.[Processing Status] = 5 --completed
--	 group by
--		[Buying Reference No_]
--	) pr
--on			
--	sh.[External Document No_] = pr.[Buying Reference No_]	
where
	sh.[No_] = @orderNo
and sh.[Order Date] >= datefromparts(2021,8,1)
--and pr.[Payment Date] >= datefromparts(2021,8,1)
and sl.[Location Code] in ('WASDSP')  --iOOS Condition
and cr.[Is iOSS] = 1 --iOOS Condition
group by
	sh.[No_]
having
	sum(sl.[Amount Including VAT]/case when ceiling(sh.[Currency Factor]) > 0 then sh.[Currency Factor] else 1 end) < 125

if @check is null

select @check = 0

return @check

end
GO
