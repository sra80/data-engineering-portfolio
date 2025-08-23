create or alter view [price_tool_feed].[articles_lookup]

as

--used by a process made by Simon to assist Laura with bulk file compilation

select
   i.ID article_id,
   ii.No_ article_sku
from
    ext.Item i
join
    hs_consolidated.[Item] ii
on
    (
        i.company_id = ii.company_id
    and i.No_ = ii.No_        
    )
where
    (
        i.company_id = 1
    and ii.[Type] = 0
    and ii.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
    and     
        (
            i.ID in (select article_id from price_tool_feed.sales_all)
        or  i.No_ in (select [BOM Item No_] from ext.Sales_Line_Archive)
        )
    )
GO
