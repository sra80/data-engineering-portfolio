
CREATE procedure [ext].[sp_ReturnComplaints]

as 

delete from ext.ReturnComplaints where [Date] < datefromparts(year(getdate())-1,1,1)

merge ext.ReturnComplaints t
using
	(
	select
		 rrh.[Posting Date] [Date]
		,rrh.[No_] [Return Receipt]
		,rrl.[Line No_] [Return Receipt Line]
		,i.[Range Code] [Range]
		,rrh.[Sell-to Customer No_] [Customer]
		,rrl.[No_] [Item No]
		,i.[Description] [Item Description]
		,rrl.[Quantity]
		,case	
			when rrl.[Return Type] = 0 then ''
			when rrl.[Return Type] = 1 then 'Exchange'
			when rrl.[Return Type] = 2 then 'Replacement'
			when rrl.[Return Type] = 3 then 'Refund'
			when rrl.[Return Type] = 4 then 'Account Credit'
		 end [Return Type]
		,rrl.[Return Reason Code]
		,rr.[Description] [Return Reason Description]
		,case 
			when patindex('QA%',rrl.[Return Reason Code]) = 1 then 'Objective Quality'
			when patindex('QB%',rrl.[Return Reason Code]) = 1 then 'Subjective Quality'
			when patindex('O%',rrl.[Return Reason Code]) = 1 then 'Postal'
			else 'Order'
		 end [Type]
		,(select top 1 scl.[Comment] from [hs_consolidated].[Sales Comment Line] scl where scl.[company_id] = rrl.[company_id] and scl.[No_] = rrl.[Document No_] and scl.[Document Line No_] = rrl.[Line No_] and len(scl.[Comment]) > 0) [Comment]
		,rrh.[Sales Order Reference]
		,(select top 1 [Lot No_] from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 and ile.[company_id] = rrl.[company_id] and ile.[External Document No_] = rrh.[External Document No_] and ile.[Item No_] = rrl.[No_]) [Lot No]
		,(select top 1 [Order Date] from [hs_consolidated].[Sales Invoice Header] sih where sih.[company_id] = rrh.[company_id] and sih.[Order No_] = rrh.[Sales Order Reference]) [Original Order Date]
		,(select -sum([Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 and ile.[company_id] = rrl.[company_id] and ile.[Posting Date] = rrl.[Posting Date] and ile.[Item No_] = rrl.[No_]) [Units Sold]
		,rrh.[Order Created by] [Return Created By]
		,c.[ID] [company_id]
		,c.[Company]
		,checksum(i.[Range Code],i.[Description],rr.[Description],(select top 1 scl.[Comment] from [hs_consolidated].[Sales Comment Line] scl where scl.[company_id] = rrl.[company_id] and scl.[No_] = rrl.[Document No_] and scl.[Document Line No_] = rrl.[Line No_] and len(scl.[Comment]) > 0),(select top 1 [Lot No_] from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 and ile.[company_id] = rrl.[company_id] and ile.[External Document No_] = rrh.[External Document No_] and ile.[Item No_] = rrl.[No_]),(select -sum([Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 and ile.[company_id] = rrl.[company_id] and ile.[Posting Date] = rrl.[Posting Date] and ile.[Item No_] = rrl.[No_])) dbo_checksum
	from
		[hs_consolidated].[Return Receipt Header] rrh
	join
		[hs_consolidated].[Return Receipt Line] rrl
	on
		(
			rrh.[company_id] = rrl.[company_id]
		and rrh.[No_] = rrl.[Document No_]
		)
	join
		[hs_consolidated].[Item] i
	on
		(
			i.[company_id] = rrl.[company_id]
		and i.[No_] = rrl.[No_]
		)
	join
		[hs_consolidated].[Return Reason] rr
	on
		(
			rr.[company_id] = rrl.[company_id]
		and rr.[Code] = rrl.[Return Reason Code]
		)
	join
		[db_sys].[Company] c
	on
		c.[ID] = rrh.[company_id]
	where
		rrh.[Posting Date] >= datefromparts(year(getdate())-1,1,1)
	) s
on
	(
		t.company_id = s.[company_id]
	and t.[Return Receipt] = s.[Return Receipt]
	and t.[Return Receipt Line] = s.[Return Receipt Line]	
	)
when not matched by target then
	insert ([Date],[Return Receipt],[Return Receipt Line],[Range],[Customer],[Item],[Item Description],[Quantity],[Return Type],[Return Reason Code],[Return Reason Description],[Type],[Comment],[Sales Order Reference],[Lot No],[Original Order Date],[Units Sold],[Return Created By],[company_id],[Company],dbo_checksum)
	values (s.[Date],s.[Return Receipt],s.[Return Receipt Line],s.[Range],s.[Customer],s.[Item No],s.[Item Description],s.[Quantity],s.[Return Type],s.[Return Reason Code],s.[Return Reason Description],s.[Type],s.[Comment],s.[Sales Order Reference],s.[Lot No],s.[Original Order Date],s.[Units Sold],s.[Return Created By],s.[company_id],s.[Company],s.dbo_checksum)
when matched and isnull(t.dbo_checksum,0) != s.dbo_checksum then update set
	t.[Range] = s.[Range],
	t.[Item Description] = s.[Item Description],
	t.[Return Reason Description] = s.[Return Reason Description],
	t.[Comment] = s.[Comment],
	t.[Lot No] = s.[Lot No],
	t.[Units Sold] = s.[Units Sold];
GO
