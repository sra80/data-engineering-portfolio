create view ext.vw_InternationSales_Missing_InboundTable

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
            [UK$Inbound Sales Header] nav
        on
            (
                h.[ExternalOrderReference] = nav.[Document No_]
            )
        where
            nav.[Document No_] is null
        and h.[ExternalOrderReference] is not null
        and h.CurrentVersion = 1
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
