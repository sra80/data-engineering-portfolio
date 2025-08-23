
CREATE   view [stock].[WarehouseLocation]

as

select 
	c.ID company_id,
    ext.ID key_location,
    c.Company,
	isnull(nullif(dbo.[Name],''),dbo.Code) [Location],
    (select ID from ext.Country_Region cr where cr.company_id = dbo.company_id and cr.country_code = isnull(ext.country,(select Country from db_sys.Company c where c.ID = dbo.company_id))) [Country],
    case when distribution_loc = 1 then 'Yes' else 'No' end [Distribution Location],
    case when holding_loc = 1 then 'Yes' else 'No' end [Holding Location],
    case when transit_loc = 1 then 'Yes' else 'No' end [Transit Location]
from 
	[hs_consolidated].[Location] dbo
join
    ext.[Location] ext
on
    (
        dbo.company_id = ext.company_id
    and dbo.Code = ext.location_code
    )
join
    db_sys.Company c
on
    (
        dbo.company_id = c.ID
    )
GO
