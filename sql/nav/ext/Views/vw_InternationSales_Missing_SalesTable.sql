create view ext.vw_InternationSales_Missing_SalesTable

as

select 
    x.ExternalOrderReference, 
    y.OrderDate,
    x.LineNet, 
    x.LineGross
from
    (
        select 
            h.ExternalOrderReference, 
            sum(l.LineNet) LineNet, 
            sum(l.LineGross) LineGross
        from	 
            dbo.F18_Sales_Header h
        join
            dbo.F19_Sales_Line l
        on
            (
                h.PlatformID = l.PlatformID
            and h.ID = l.Sales_HeaderID
            and h.OrderVersion = l.OrderVersion
            )
        left join
            (select No_ [Document No_] from ext.Sales_Header where [Sales Order Status] = 1 union select No_ from ext.Sales_Header_Archive) nav
        on
            (
                h.[ExternalOrderReference] = nav.[Document No_]
            )
        where
            nav.[Document No_] is null
        and h.[ExternalOrderReference] is not null
        and h.CurrentVersion = 1
        and year(h.OrderDate) >= 2022
        and year(h.OrderDate) >= year(getutcdate()) - 2 --within range of ext sales tables
        and h.Currency = 'NZD'
        group by
            h.ExternalOrderReference
    ) x
join
    dbo.F18_Sales_Header y
on
    (
        x.ExternalOrderReference = y.ExternalOrderReference
    )
GO
