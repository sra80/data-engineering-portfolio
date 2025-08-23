CREATE view forecast_feed.moq_blocked_vendor

as

select 
    c.NAV_DB [Company],
    concat(v.[Name],' (',v.No_,')') Vendor,
    pp.[Item No_] [Item Code],
    isnull(convert(nvarchar,nullif(pp.[Starting Date],datefromparts(1753,1,1)),103),'') [Starting Date],
    ceiling(pp.[Minimum Quantity]) [Minimum Quantity]
from 
    db_sys.Company c 
join 
    [hs_consolidated].[Purchase Price] pp
on 
    (
        c.ID = pp.company_id
    )
join 
    hs_consolidated.[Vendor] v 
on 
    (
        pp.company_id = v.company_id
    and pp.[Vendor No_] = v.No_
    ) 
join
    forecast_feed.item i
on
    (
        pp.[Item No_] = i.item_code
    )
where 
    (
        pp.[Ending Date] = '17530101'
    and v.[Blocked] > 0
    )
GO
