
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create or alter procedure [ext].[sp_QualityReturns]
  
as

set nocount on 

-- commented out the delete statement as per the #58074 as historical data from 2018 onwards is required
--delete from [ext].[QualityReturns] where convert(date,convert(nvarchar,[keyDate])) < datefromparts(year(getdate())-1,1,1)

--incremental load
;with x
as
(
	select 
		rrl.company_id,
		c.[Company],
		rrh.[No_] [Return Document],
		rrl.[Line No_] [Line No],
		convert(int,format(rrh.[Posting Date],'yyyyMMdd')) [keyDate],
		i.[Range Code],
		rrl.[Sell-to Customer No_] [Customer No],
		rrl.[No_] [Item No],
		ibi.item_ID,
		i.[Description] [Item Description],
		rrl.[Quantity],
		db_sys.fn_Lookup('Return Receipt Line','Return Type',rrl.[Return Type]) [Return Type],--l.[_value] [Return Type],
		case	
			when patindex('QA%',rrl.[Return Reason Code]) = 1 then 0--'Objective'
			else 1--'Subjective'
		end [keyQualityType],
		rrl.[Return Reason Code],
		rr.[Description] [Return Reason Description],
		(select top 1 scl.[Comment] from [hs_consolidated].[Sales Comment Line] scl where scl.[No_] = rrl.[Document No_] and scl.[Document Line No_] = rrl.[Line No_] and scl.[company_id] = rrl.[company_id] and len(scl.[Comment]) > 0 and scl.[Date] > '17530101') [Comment],
		rrh.[Sales Order Reference],
        ibi.[ID] [batchID],
		ibi.batch_no [Lot No],
		(select top 1 [Order Date] from [hs_consolidated].[Sales Header Archive] sha where sha.[company_id] = rrh.[company_id] and sha.[No_] = rrh.[Sales Order Reference]) [Date of Original Order],
		rrh.[Order Created by] [Return Created By],
		ibi.exp
	from
		[hs_consolidated].[Return Receipt Line] rrl
	join
		[hs_consolidated].[Return Receipt Header] rrh
	on
		(
			rrl.[Document No_] = rrh.[No_]
		and rrl.[company_id] = rrh.[company_id]
		)
	join
		[hs_consolidated].[Item] i
	on
		(
			rrl.[No_] = i.[No_]
		and rrl.[company_id] = i.[company_id]
		)
	join
		ext.Return_Receipt_Line e_rrl
	on
		(
			rrl.company_id = e_rrl.company_id
		and rrl.[Document No_] = e_rrl.[Document No_]
		and rrl.[Line No_] = e_rrl.[Line No_]
		)
	join    
		ext.Item_Batch_Info ibi
	on
		(
			e_rrl.batch_id = ibi.ID
		)
	join
		[hs_consolidated].[Return Reason] rr
	on
		(
			rr.[Code] = rrl.[Return Reason Code]
		and rr.[company_id] = rrl.[company_id]
		)
	join
		[db_sys].[Company] c
	on
		(
			rrl.company_id = c.[ID]
		)
	where
		rrh.[Posting Date] >= dateadd(day,1,eomonth(getutcdate(),-2)) --datefromparts(year(dateadd(month,-2,getdate())),month(dateadd(month,-1,getdate())),1)-- step 5 #58074 datefromparts(year(getdate())-1,1,1)
	-- and patindex('Q%',rrl.[Return Reason Code]) = 1 --replaced patindex with below for performance optimization as part of work under #58074
	and e_rrl.is_QR = 1
)


insert into [ext].[QualityReturns] (company_id, [itemID], [Company], [Return Document], [Line No], [keyDate], [Range Code], [Customer No], [Item No], [Item Description], [Quantity], [Return Type], [keyQualityType], [Return Reason Code], [Return Reason Description], [Comment], [Sales Order Reference], [batchID], [Lot No], [Date of Original Order], [Return Created By], [Expiry Date])
select
	x.company_id,
	x.item_ID,
    x.[Company],
    x.[Return Document], 
    x.[Line No], 
    x.[keyDate], 
    x.[Range Code], 
    x.[Customer No], 
    x.[Item No], 
    x.[Item Description], 
    x.[Quantity], 
    x.[Return Type], 
    x.[keyQualityType], 
    x.[Return Reason Code], 
    x.[Return Reason Description],
    x.[Comment], 
    x.[Sales Order Reference], 
    x.[batchID],
    replace(x.[Lot No],'','Not Provided') [Lot No],
    x.[Date of Original Order], 
    x.[Return Created By],
	x.exp
from
    x
where
    (
		not exists (select 1 from [ext].[QualityReturns] qr where qr.[Company] = x.[Company] and qr.[Return Document] = x.[Return Document] and qr.[Line No] =  x.[Line No])
	)

/*
--one off load to insert data from 2018 - 2023 re ##58074

;with x
as
(
	select 
		rrl.company_id,
		c.[Company],
		rrh.[No_] [Return Document],
		rrl.[Line No_] [Line No],
		convert(int,format(rrh.[Posting Date],'yyyyMMdd')) [keyDate],
		i.[Range Code],
		rrl.[Sell-to Customer No_] [Customer No],
		rrl.[No_] [Item No],
		ibi.item_ID,
		i.[Description] [Item Description],
		rrl.[Quantity],
		db_sys.fn_Lookup('Return Receipt Line','Return Type',rrl.[Return Type]) [Return Type],--l.[_value] [Return Type],
		case	
			when patindex('QA%',rrl.[Return Reason Code]) = 1 then 0--'Objective'
			else 1--'Subjective'
		end [keyQualityType],
		rrl.[Return Reason Code],
		rr.[Description] [Return Reason Description],
		(select top 1 scl.[Comment] from [hs_consolidated].[Sales Comment Line] scl where scl.[No_] = rrl.[Document No_] and scl.[Document Line No_] = rrl.[Line No_] and scl.[company_id] = rrl.[company_id] and len(scl.[Comment]) > 0 and scl.[Date] > '17530101') [Comment],
		rrh.[Sales Order Reference],
        ibi.[ID] [batchID],
		ibi.batch_no [Lot No],
		(select top 1 [Order Date] from [hs_consolidated].[Sales Header Archive] sha where sha.[company_id] = rrh.[company_id] and sha.[No_] = rrh.[Sales Order Reference]) [Date of Original Order],
		rrh.[Order Created by] [Return Created By],
		ibi.exp
	from
		[hs_consolidated].[Return Receipt Line] rrl
	join
		[hs_consolidated].[Return Receipt Header] rrh
	on
		(
			rrl.[Document No_] = rrh.[No_]
		and rrl.[company_id] = rrh.[company_id]
		)
	join
		[hs_consolidated].[Item] i
	on
		(
			rrl.[No_] = i.[No_]
		and rrl.[company_id] = i.[company_id]
		)
	join
		ext.Return_Receipt_Line e_rrl
	on
		(
			rrl.company_id = e_rrl.company_id
		and rrl.[Document No_] = e_rrl.[Document No_]
		and rrl.[Line No_] = e_rrl.[Line No_]
		)
	join    
		ext.Item_Batch_Info ibi
	on
		(
			e_rrl.batch_id = ibi.ID
		)
	join
		[hs_consolidated].[Return Reason] rr
	on
		(
			rr.[Code] = rrl.[Return Reason Code]
		and rr.[company_id] = rrl.[company_id]
		)
	join
		[db_sys].[Company] c
	on
		(
			rrl.company_id = c.[ID]
		)
	where
		rrh.[Posting Date] >= datefromparts(year(getdate())-7,1,1)
    and rrh.[Posting Date] < datefromparts(year(getdate())-1,1,1)
	-- and patindex('Q%',rrl.[Return Reason Code]) = 1 --replaced patindex with below for performance optimization as part of work under #58074
	and e_rrl.is_QR = 1
)


insert into [ext].[QualityReturns] (company_id, [itemID], [Company], [Return Document], [Line No], [keyDate], [Range Code], [Customer No], [Item No], [Item Description], [Quantity], [Return Type], [keyQualityType], [Return Reason Code], [Return Reason Description], [Comment], [Sales Order Reference], [batchID], [Lot No], [Date of Original Order], [Return Created By], [Expiry Date])
select
	x.company_id,
	x.item_ID,
    x.[Company],
    x.[Return Document], 
    x.[Line No], 
    x.[keyDate], 
    x.[Range Code], 
    x.[Customer No], 
    x.[Item No], 
    x.[Item Description], 
    x.[Quantity], 
    x.[Return Type], 
    x.[keyQualityType], 
    x.[Return Reason Code], 
    x.[Return Reason Description],
    x.[Comment], 
    x.[Sales Order Reference], 
    x.[batchID],
    replace(x.[Lot No],'','Not Provided') [Lot No],
    x.[Date of Original Order], 
    x.[Return Created By],
	x.exp
from
    x
where
    (
		not exists (select 1 from [ext].[QualityReturns] qr where qr.[Company] = x.[Company] and qr.[Return Document] = x.[Return Document] and qr.[Line No] =  x.[Line No])
	)
*/

/*
--full load

truncate table [ext].[QualityReturns]

;with x
as
(
	select 
		rrl.company_id,
		c.[Company],
		rrh.[No_] [Return Document],
		rrl.[Line No_] [Line No],
		convert(int,format(rrh.[Posting Date],'yyyyMMdd')) [keyDate],
		i.[Range Code],
		rrl.[Sell-to Customer No_] [Customer No],
		rrl.[No_] [Item No],
		ibi.item_ID,
		i.[Description] [Item Description],
		rrl.[Quantity],
		db_sys.fn_Lookup('Return Receipt Line','Return Type',rrl.[Return Type]) [Return Type],--l.[_value] [Return Type],
		case	
			when patindex('QA%',rrl.[Return Reason Code]) = 1 then 0--'Objective'
			else 1--'Subjective'
		end [keyQualityType],
		rrl.[Return Reason Code],
		rr.[Description] [Return Reason Description],
		(select top 1 scl.[Comment] from [hs_consolidated].[Sales Comment Line] scl where scl.[No_] = rrl.[Document No_] and scl.[Document Line No_] = rrl.[Line No_] and scl.[company_id] = rrl.[company_id] and len(scl.[Comment]) > 0 and scl.[Date] > '17530101') [Comment],
		rrh.[Sales Order Reference],
        ibi.[ID] [batchID],
		ibi.batch_no [Lot No],
		(select top 1 [Order Date] from [hs_consolidated].[Sales Header Archive] sha where sha.[company_id] = rrh.[company_id] and sha.[No_] = rrh.[Sales Order Reference]) [Date of Original Order],
		rrh.[Order Created by] [Return Created By],
		ibi.exp
	from
		[hs_consolidated].[Return Receipt Line] rrl
	join
		[hs_consolidated].[Return Receipt Header] rrh
	on
		(
			rrl.[Document No_] = rrh.[No_]
		and rrl.[company_id] = rrh.[company_id]
		)
	join
		[hs_consolidated].[Item] i
	on
		(
			rrl.[No_] = i.[No_]
		and rrl.[company_id] = i.[company_id]
		)
	join
		ext.Return_Receipt_Line e_rrl
	on
		(
			rrl.company_id = e_rrl.company_id
		and rrl.[Document No_] = e_rrl.[Document No_]
		and rrl.[Line No_] = e_rrl.[Line No_]
		)
	join    
		ext.Item_Batch_Info ibi
	on
		(
			e_rrl.batch_id = ibi.ID
		)
	join
		[hs_consolidated].[Return Reason] rr
	on
		(
			rr.[Code] = rrl.[Return Reason Code]
		and rr.[company_id] = rrl.[company_id]
		)
	join
		[db_sys].[Company] c
	on
		(
			rrl.company_id = c.[ID]
		)
	where
		rrh.[Posting Date] >= datefromparts(year(getdate())-7,1,1)
	-- and patindex('Q%',rrl.[Return Reason Code]) = 1 --replaced patindex with below for performance optimization as part of work under #58074
	and e_rrl.is_QR = 1
)


insert into [ext].[QualityReturns] (company_id, [itemID], [Company], [Return Document], [Line No], [keyDate], [Range Code], [Customer No], [Item No], [Item Description], [Quantity], [Return Type], [keyQualityType], [Return Reason Code], [Return Reason Description], [Comment], [Sales Order Reference], [batchID], [Lot No],  [Date of Original Order], [Return Created By], [Expiry Date])
select
	x.company_id,
	x.item_ID,
    x.[Company],
    x.[Return Document], 
    x.[Line No], 
    x.[keyDate], 
    x.[Range Code], 
    x.[Customer No], 
    x.[Item No], 
    x.[Item Description], 
    x.[Quantity], 
    x.[Return Type], 
    x.[keyQualityType], 
    x.[Return Reason Code], 
    x.[Return Reason Description],
    x.[Comment], 
    x.[Sales Order Reference], 
    x.[batchID],
    replace(x.[Lot No],'','Not Provided') [Lot No],
    x.[Date of Original Order], 
    x.[Return Created By],
	x.exp
from
    x

*/
GO