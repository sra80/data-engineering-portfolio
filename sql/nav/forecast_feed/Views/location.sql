CREATE view [forecast_feed].[location]

as

select 
    a.location_ID key_location,
    a.location_code,
    l2.[Name] location_name,
    a.distribution_loc [distribution],
    a.holding_loc stock_holding
from 
    [forecast_feed].[location_overide_aggregate] a
join
    ext.Location l
on
    a.location_ID = l.ID
join
    hs_consolidated.Location l2
on
    (
        l.company_id = l2.company_id
    and l.location_code = l2.Code
    )
where
    (
        a.location_ID = a.location_ID_overide
    )
GO
