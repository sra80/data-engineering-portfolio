
create   view [marketing].[WarehouseLocation]

as

select 
	 e.ID key_location
	,isnull(nullif(h.[Name],''),Code) [Location]
from 
	hs_consolidated.[Location] h
join
    ext.Location e
on
    (
        h.company_id = e.company_id
    and h.Code = e.location_code
    )
GO
