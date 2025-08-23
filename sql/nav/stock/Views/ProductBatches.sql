create or alter view [stock].[ProductBatches]

as

/*
07/06/2021 12:47 Latest Despatch Date adopted from [ext].[sp_Item_OOS]
21/06/2021 17:28 Add product info to batch info, optimization of model
17/08/2021 13:01 Get expiry and despatch from received line rather than trying to find most recent entry against product & batch - performance optimization, e.g. a static table no longer needed behind Stock at Risk Analysis Power BI Report
20/08/2021 05:12 Switch logic for obtaining the expiration date and latest despatch date to the same logic within NAV that is applied in the Lot Information table - see e-mail from Adam, also have a file demonstrating comparison in Project 145 under documents
28/10/2021 13:14 Add key_sku_single for OOS relationship in the model Logistics_StockManagement
09/03/2022 08:45 Add handling for invalid batch codes
09/05/2023 19:53 (CAT) Switch to multi-company
31/10/2023 Set source of exp & ldd to ext.Item_Batch_Info ibi (maintained by sp ext.sp_Item_Batch_Info)
28/10/2024 Add Batch Unit Cost
*/

select
    p.key_sku,
    ibi.ID key_batch,
    p.[Item Code],
    p.[Item Name],
    p.[Item Category],
    p.[Item Range],
    p.[Item Reporting Group],
    p.[Item Legal Entity],
    p.[Item Status],
    isnull(nullif(ibi.batch_no,''),'Not Provided') [Batch Number],
    round(ext.fn_Convert_Currency_GBP(ibi.unit_cost,ibi.company_id,ibi.addedTSUTC),2) [Batch Unit Cost],
    p.[Unit of Measure],
    p.[First Order Year],
    p.[First Order Date],
    p.[Inventory Posting],
    p.[Inventory Posting Group],
    p.FSAI,
    p.[Item Tracking Code],
    isnull(ibi.exp,datefromparts(2099,12,31)) [Expiration Date],
    isnull(ibi.ldd,datefromparts(2099,12,31)) [Latest Despatch Date]
from
    stock.Product p
join
    ext.Item_Batch_Info ibi
on
    (
        p.company_id = ibi.company_id
    and p.[Item Code] = ibi.sku
    )

GO