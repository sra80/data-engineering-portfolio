SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create or alter PROCEDURE [ext].[sp_QualityReturnedProducts]
  
as

set nocount on 

delete from [ext].[QualityReturnedProducts] where [Return Year] < year(getdate())-7/*year(getdate())-1*/

/*
--FULL LOAD - 7 years ago

;with x as
(
    select
        [itemID], 
        [batchID],
        [company_id],
        [Item No],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID]
    from
        ext.QualityReturns x
    where   
        year(convert(date,convert(nvarchar,[keyDate]))) = year(getdate())-7
    group by
        [company_id],
        [batchID],
        [Item No],
        [itemID], 
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
)

insert into [ext].[QualityReturnedProducts] ([_itemID], [_batchID], [Lot No], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID])
select
    [itemID], 
    [batchID],
    [Lot No],
    [Return Year],
    [_keyQualityType],
    [Expiry Date],
    [Returned Quantity By _itemID],
    isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-7,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
    isnull(x.[Returned Quantity By _itemID]/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-7,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID] 
from
    x

*/

/*
--FULL LOAD - 6 years ago

;with x as
(
    select
        [itemID], 
        [batchID],
        [company_id],
        [Item No],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID]
    from
        ext.QualityReturns x
    where   
        year(convert(date,convert(nvarchar,[keyDate]))) = year(getdate())-6
    group by
        [company_id],
        [batchID],
        [Item No],
        [itemID], 
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
)

insert into [ext].[QualityReturnedProducts] ([_itemID], [_batchID], [Lot No], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID])
select
    [itemID], 
    [batchID],
    [Lot No],
    [Return Year],
    [_keyQualityType],
    [Expiry Date],
    [Returned Quantity By _itemID],
    isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-6,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
    isnull(x.[Returned Quantity By _itemID]/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-6,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID] 
from
    x

*/

/*
--FULL LOAD - 5 years ago

;with x as
(
    select
        [itemID], 
        [batchID],
        [company_id],
        [Item No],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID]
    from
        ext.QualityReturns x
    where   
        year(convert(date,convert(nvarchar,[keyDate]))) = year(getdate())-5
    group by
        [company_id],
        [batchID],
        [Item No],
        [itemID], 
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
)

insert into [ext].[QualityReturnedProducts] ([_itemID], [_batchID], [Lot No], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID])
select
    [itemID], 
    [batchID],
    [Lot No],
    [Return Year],
    [_keyQualityType],
    [Expiry Date],
    [Returned Quantity By _itemID],
    isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-5,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
    isnull(x.[Returned Quantity By _itemID]/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-5,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID] 
from
    x

*/

/*
--FULL LOAD - 4 years ago

;with x as
(
    select
        [itemID], 
        [batchID],
        [company_id],
        [Item No],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID]
    from
        ext.QualityReturns x
    where   
        year(convert(date,convert(nvarchar,[keyDate]))) = year(getdate())-4
    group by
        [company_id],
        [batchID],
        [Item No],
        [itemID], 
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
)

insert into [ext].[QualityReturnedProducts] ([_itemID], [_batchID], [Lot No], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID])
select
    [itemID], 
    [batchID],
    [Lot No],
    [Return Year],
    [_keyQualityType],
    [Expiry Date],
    [Returned Quantity By _itemID],
    isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-4,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
    isnull(x.[Returned Quantity By _itemID]/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-4,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID] 
from
    x

*/

/*
--FULL LOAD - 3 years ago

;with x as
(
    select
        [itemID], 
        [batchID],
        [company_id],
        [Item No],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID]
    from
        ext.QualityReturns x
    where   
        year(convert(date,convert(nvarchar,[keyDate]))) = year(getdate())-3
    group by
        [company_id],
        [batchID],
        [Item No],
        [itemID], 
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
)

insert into [ext].[QualityReturnedProducts] ([_itemID], [_batchID], [Lot No], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID])
select
    [itemID], 
    [batchID],
    [Lot No],
    [Return Year],
    [_keyQualityType],
    [Expiry Date],
    [Returned Quantity By _itemID],
    isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-3,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
    isnull(x.[Returned Quantity By _itemID]/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-3,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID] 
from
    x

*/

/*
--FULL LOAD - year before last
;with x as
(
    select
        [itemID], 
        [batchID],
        [company_id],
        [Item No],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID]
    from
        ext.QualityReturns x
    where   
        year(convert(date,convert(nvarchar,[keyDate]))) = year(getdate())-2
    group by
        [company_id],
        [batchID],
        [Item No],
        [itemID], 
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
)

insert into [ext].[QualityReturnedProducts] ([_itemID], [_batchID], [Lot No], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID])
select
    [itemID], 
    [batchID],
    [Lot No],
    [Return Year],
    [_keyQualityType],
    [Expiry Date],
    [Returned Quantity By _itemID],
    isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-2,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
    isnull(x.[Returned Quantity By _itemID]/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-2,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID] 
from
    x

*/

/*
--FULL LOAD - last year

--truncate table [ext].[QualityReturnedProducts]

;with x as
(
    select
        [itemID], 
        [batchID],
        [company_id],
        [Item No],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID]
    from
        ext.QualityReturns x
    where   
        year(convert(date,convert(nvarchar,[keyDate]))) = year(getdate())-1
    group by
        [company_id],
        [batchID],
        [Item No],
        [itemID], 
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
)

insert into [ext].[QualityReturnedProducts] ([_itemID], [_batchID], [Lot No], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID])
select
    [itemID], 
    [batchID],
    [Lot No],
    [Return Year],
    [_keyQualityType],
    [Expiry Date],
    [Returned Quantity By _itemID],
    isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-1,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
    isnull(x.[Returned Quantity By _itemID]/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/and ile.[Posting Date] <= datefromparts(year(getdate())-1,12,31) and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID] 
from
    x

*/

/*
--FULL LOAD - this year

;with x as
(
    select
        [itemID], 
        [batchID],
        [company_id],
        [Item No],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID]
    from
        ext.QualityReturns x
    where   
        year(convert(date,convert(nvarchar,[keyDate]))) = year(getdate())
    group by
        [company_id],
        [batchID],
        [Item No],
        [itemID], 
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
)

insert into [ext].[QualityReturnedProducts] ([_itemID], [_batchID], [Lot No], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID])
select
    [itemID], 
    [batchID],
    [Lot No],
    [Return Year],
    [_keyQualityType],
    [Expiry Date],
    [Returned Quantity By _itemID],
    isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*//*and ile.[Posting Date] <= datefromparts(year(getdate())-1,12,31)*/ and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
    isnull(x.[Returned Quantity By _itemID]/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*//*and ile.[Posting Date] <= datefromparts(year(getdate())-1,12,31)*/ and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID] 
from
    x
*/

merge [ext].[QualityReturnedProducts] t --target
using 
    (
    select
        [itemID], 
        [batchID],
        [Lot No],
        keyDate/10000 [Return Year],
        keyQualityType [_keyQualityType],  
        [Expiry Date],
        sum(Quantity) [Returned Quantity By _itemID],
        isnull(-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/ and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Units Sold By _itemID],
        isnull(sum(x.[Quantity])/-(select sum(ile.[Quantity]) from [hs_consolidated].[Item Ledger Entry] ile where ile.[Document Type] = 1 /*Sales Shipment*/ and ile.[Item No_] = x.[Item No] and ile.[Lot No_] = x.[Lot No] and ile.[company_id] = x.[company_id]),0) [Complaint Rate By _itemID]
    from
        ext.QualityReturns x
    group by
        [company_id],
        [Item No],
        [itemID], 
        [batchID],
        [Lot No],
        keyDate/10000,
        keyQualityType,  
        [Expiry Date]
    ) s--source
    on
        (
            t.[_itemID] = s.[itemID] 
        and t.[Lot No] = s.[Lot No]
        and t.[Return Year] = s.[Return Year]
        and t.[_keyQualityType] = s.[_keyQualityType]
        )
when not matched by target
    then insert ([_itemID], [_batchID], [Return Year], [_keyQualityType], [Expiry Date] , [Returned Quantity By _itemID], [Units Sold By _itemID], [Complaint Rate By _itemID], [Lot No])
    values (s.[itemID], s.[batchID], s.[Return Year], s.[_keyQualityType], s.[Expiry Date] , s.[Returned Quantity By _itemID], s.[Units Sold By _itemID] , s.[Complaint Rate By _itemID], s.[Lot No])
when matched and (t.[Returned Quantity By _itemID] <> s.[Returned Quantity By _itemID] or  t.[Units Sold By _itemID] <> s.[Units Sold By _itemID] or t.[Complaint Rate By _itemID] <> s.[Complaint Rate By _itemID])
    then update set t.[Returned Quantity By _itemID] = s.[Returned Quantity By _itemID],  t.[Units Sold By _itemID] = s.[Units Sold By _itemID] , t.[Complaint Rate By _itemID] = s.[Complaint Rate By _itemID];

GO