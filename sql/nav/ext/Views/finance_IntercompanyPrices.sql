




CREATE view [ext].[finance_IntercompanyPrices]

as

select 
	 c.[Company]
	,i.[No_] [Item No]
	,i.[Description] [Item Name]
	,ile.[Lot No_] [Lot No]
	,nullif(ile1.[Expiration Date],'17530101') [Expiration Date]
	,nullif(ile2.[Latest Despatch Date],'17530101') [Latest Despatch Date]
	,ile.[Available Stock (WASDSP)]
	,ile.[AVG Cost (GBP)] [AVG Cost (GBP)]
	,case
		when c.[ID] = 5 then 'NZD' else 'EUR'
	 end [Currency]
	,case
		when c.[ID] = 5 then ile.[AVG Cost (GBP)] * (select top 1 [Exchange Rate Amount] from [dbo].[UK$Currency Exchange Rate] where [Currency Code] = 'NZD' order by [Starting Date] desc)
		else ile.[AVG Cost (GBP)] * (select top 1 [Exchange Rate Amount] from [dbo].[UK$Currency Exchange Rate] where [Currency Code] = 'EUR' order by [Starting Date] desc)
	 end [AVG Cost (LCY)]
from
	[hs_consolidated].[Item] i
join
	[db_sys].[Company] c
on
	(
		i.[company_id] = c.[ID]
	)
join
	(
		select
			 ile.[Item No_]
			,ile.[Lot No_]
			,sum(ile.[Remaining Quantity]) [Available Stock (WASDSP)]
			,sum(ve.[Cost])/sum(ile.[Quantity]) [AVG Cost (GBP)]
		from
			[dbo].[UK$Item Ledger Entry] ile
		join
			(select
				[Item Ledger Entry No_]
				,sum(ve.[Cost Amount (Actual)] + [Cost Amount (Expected)]) [Cost]
			from
				[dbo].[UK$Value Entry] ve
			group by
				[Item Ledger Entry No_]
			) ve
		on
			(
				ile.[Entry No_] = ve.[Item Ledger Entry No_]
			)
		where
			ile.[Location Code] = 'WASDSP'
		and ile.[Remaining Quantity] <> 0
		group by
			 ile.[Item No_]
			,ile.[Lot No_]
	) ile
on
	(
		i.[No_] = ile.[Item No_]
	)
left join
	(
		select		
			 [Item No_]	
			,[Lot No_]	
			,max([Expiration Date]) [Expiration Date]	
		from		
			[NAV_PROD_REPL].[dbo].[UK$Item Ledger Entry] (nolock)	
		where		
			[Positive] = 1	
		and [Location Code] = 'WASDSP'		
		group by		
			 [Item No_]	
			,[Lot No_]	
	) ile1
on
	(
		ile1.[Item No_] = ile.[Item No_]			
	and	ile1.[Lot No_] = ile.[Lot No_]			
	)
left join
	(
		select			
			 [Item No_]		
			,[Lot No_]		
			,max([Latest Despatch Date]) [Latest Despatch Date]		
		from			
			[NAV_PROD_REPL].[dbo].[UK$Item Ledger Entry] (nolock)		
		where			
			[Positive] = 1		
		and [Latest Despatch Date] > '17530101'			
		--and [Location Code] = 'WASDSP'			
		group by			
			 [Item No_]		
			,[Lot No_]	
	) ile2
on
	(
		ile2.[Item No_] = ile.[Item No_]			
	and	ile2.[Lot No_] = ile.[Lot No_]		
	)
where
	[company_id] in (5,6)
and [Gen_ Prod_ Posting Group] = 'ITEM'
GO

GRANT SELECT
    ON OBJECT::[ext].[finance_IntercompanyPrices] TO [All CompanyX Staff]
    AS [dbo];
GO
