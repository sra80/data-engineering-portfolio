
	

CREATE PROCEDURE [ext].[sp_iOSS]

as

set nocount on

delete from [ext].[iOSS] where eomonth([Payment Date]) = eomonth(getutcdate(),-1)

insert into [ext].[iOSS] ([Invoice No],[Customer],[Customer No],[Delivery Country],[Customer Country],[Order Date],[Payment Date],[Order No],[Invoice Date],[Line No],[Item No],[Item Description],[Catalogue Code],[VAT Business Posting Group],[VAT Product Posting Group],[Quantity],[Unit of Measure Code],[Unit Price],[Amount Including VAT],[VAT Amount],[Line Discount Amount],[Manual Discount Amount],[Promotion Discount Amount],[System Discount Amount],[iOSS Amount],[iOSS Amount Including VAT],[iOSS VAT Amount],[iOSS Amount (LCY)])
select 			
	 isnull(si.[invoiceNo],'Not Posted') [Invoice No]		
	,isnull(si.[Ship-to Name],sh.[Ship-to Name]) [Customer]		
	,isnull(si.[Sell-to Customer No_],sh.[Sell-to Customer No_]) [Customer No]		
	,isnull(si.[Ship-to Country_Region Code],sh.[Ship-to Country_Region Code]) [Delivery Country]		
	,isnull(si.[Bill-to Country_Region Code],sh.[Bill-to Country_Region Code]) [Customer Country]		
	,isnull(si.[Order Date],sh.[Order Date]) [Order Date]		
	,pr.[Payment Date]		
	,isnull(si.[orderNo],sh.[No_]) [Order No]		
	,si.[invoiceDate] [Invoice Date]
	,coalesce(si.[Line No_],sl.[Line No_],1) [Line No]
	,isnull(si.[itemNo],sl.[No_]) [Item No]		
	,isnull(si.[Description],sl.[Description]) [Item Description]	
	,i.[Tariff No_] [Catalogue Code]		
	,isnull(si.[VAT Bus_ Posting Group], sl.[VAT Bus_ Posting Group]) [VAT Business Posting Group]		
	,isnull(si.[VAT Prod_ Posting Group],sl.[VAT Prod_ Posting Group]) [VAT Product Posting Group]		
	,isnull(si.[Quantity],sl.[Quantity]) [Quantity]		
	,isnull(si.[Unit of Measure Code],sl.[Unit of Measure Code]) [Unit of Measure Code]		
	,isnull(si.[Unit Price],sl.[Unit Price]) [Unit Price]		
	,isnull(si.[Amount Including VAT],sl.[Amount Including VAT]) [Amount Including VAT]		
	,isnull(si.[VAT Amount],sl.[Amount Including VAT]-sl.[Amount]) [VAT Amount]		
	,isnull(si.[Line Discount Amount],sl.[Line Discount Amount]) [Line Discount Amount]		
	,isnull(si.[Manual Discount Amount],sl.[Manual Discount Amount]) [Manual Discount Amount]		
	,isnull(si.[Promotion Discount Amount],sl.[Promotion Discount Amount]) [Promotion Discount Amount]		
	,isnull(si.[System Discount Amount],sl.[System Discount Amount]) [System Discount Amount]		
	,isnull(si.[iOSS Amount],sl.[iOSS Amount]) [iOSS Amount]		
    ,isnull(si.[iOSS Amount Including VAT],sl.[iOSS Amount Including VAT]) [iOSS Amount Including VAT]			
	,isnull(si.[iOSS VAT Amount],sl.[iOSS Amount Including VAT] - sl.[iOSS Amount]) [iOSS VAT Amount]		
    ,isnull(si.[iOSS Amount (LCY)],sl.[iOSS Amount (LCY)]) [iOSS Amount (LCY)]			
from			
	[dbo].[UK$Sales Line] sl		
join			
	[dbo].[UK$Sales Header] sh		
on			
	sl.[Document Type] = sh.[Document Type]		
and sl.[Document No_] = sh.[No_]			
full outer join			
	(		
		select	
			 sil.[Document No_] invoiceNo
			,sil.[Line No_]
			,sil.[No_] itemNo
			,sil.[VAT Bus_ Posting Group]
			,sil.[VAT Prod_ Posting Group]
			,sil.[Unit of Measure Code]
			,sil.[Unit Price]
			,sil.[Description]
			,sil.[Posting Date] invoiceDate
			,sih.[Is iOSS]
			,sih.[Order No_] orderNo
			,sih.[Ship-to Name]
			,sih.[Sell-to Customer No_]
			,sih.[Ship-to Country_Region Code]
			,sih.[Bill-to Country_Region Code]
			,sih.[Order Date]
			,sih.[External Document No_]
			,sil.[Quantity]
			,sil.[Amount Including VAT]
		    ,sil.[Amount Including VAT] - sil.[Amount] [VAT Amount]	
			,sil.[Line Discount Amount]
			,sil.[Manual Discount Amount]
			,sil.[Promotion Discount Amount]
			,sil.[System Discount Amount]
			,sil.[iOSS Amount]
		    ,sil.[iOSS Amount Including VAT]	
			,sil.[iOSS Amount Including VAT] - sil.[iOSS Amount] [iOSS VAT Amount] 
			,sil.[iOSS Amount (LCY)]
		from	
			[dbo].[UK$Sales Invoice Line] sil
		join	
			[dbo].[UK$Sales Invoice Header] sih
		on 	
			sil.[Document No_] = sih.[No_]
		where	
			sil.[Quantity] > 0
	) si		
on			
	si.[orderNo] = sl.[Document No_]		
and si.[itemNo] = sl.[No_]			
and si.[Line No_] = sl.[Line No_]			
join			
	[dbo].[UK$Item] i		
on			
	isnull(si.[itemNo],sl.[No_]) = i.[No_]		
join			
	(select		
		 [Buying Reference No_]	
		,min(pr.[Payment Date]) [Payment Date]	
	 from		
		[dbo].[UK$Payment_Refund] pr	
	 where		
		pr.[Type] in (1,3)	
	 and pr.[Processing Status] = 5 --completed		
	 group by		
		[Buying Reference No_]	
	) pr		
on			
	isnull(si.[External Document No_],sh.[External Document No_]) = pr.[Buying Reference No_]		
where					
	isnull(si.[Is iOSS],sh.[Is iOSS]) = 1
and eomonth(pr.[Payment Date]) =  eomonth(getutcdate(),-1)
GO
