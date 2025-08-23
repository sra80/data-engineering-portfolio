SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE or ALTER view [ext].[PromisedOrders_DiscontinuedProducts]

as

select 
     sh.[Sell-to Customer No_] [Customer No]
    ,sh.[No_] [Order No]
    ,sh.[Order Date]
    ,sh.[Channel Code]
    ,sl.[No_] [Item No]
    ,i.[Description] [Item Description]
    ,sl.[Quantity]
    ,c.[Company]
from 
    [ext].[Sales_Header] sh
join 
    [ext].[Sales_Line] sl 
on
    (
        sh.[No_] = sl.[Document No_]    
    and sh.[company_id] = sl.[company_id]
    )
join 
   [dbo].[UK$Item] i 
on
    (
        sl.[No_] = i.[No_]
    )
left join 
    [db_sys].[Lookup] l 
on
    (
        i.[Status] = l.[_key]
    )
join 
    [db_sys].[Company] c 
on
    (
        sh.[company_id] = c.[ID]
    )
where 
    (
        sh.[Sales Order Status] = 1 -- (Status = Promised)
    and l.[tableName] = 'Item'
    and l.[columnName] = 'Status'
    and i.[Status] = 2 -- (Status = Discontinued)
    and sl.[Quantity] <> 0
    )


GO