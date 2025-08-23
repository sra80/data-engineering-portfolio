
create or alter  view forecast_feed.Dimensions

as

select
    e.company_id,
    e.[Dimension Set ID] keyDimensionSetID,
    v.Code [Sale Channel Code],
    rtrim(ltrim(v.[Name])) [Sale Channel]
from
    [hs_consolidated].[Dimension Set Entry] e
join
    [hs_consolidated].[Dimension Value] v
on
    (
        e.company_id = v.company_id
    and e.[Dimension Value Code] = v.Code 
    and e.[Dimension Code] = v.[Dimension Code]
    )
where
    (
        e.[Dimension Code] = 'SALE.CHANNEL'
    )
GO
