
create   view stock.Country

as

select
    e.ID key_country,
	h.[Code] keyCountryCode,
	h.[Name] [Country],
	h.[EU Country_Region Code] [eu_code] 
from 
	[hs_consolidated].[Country_Region] h
join
    ext.Country_Region e
on
    (
        h.company_id = e.company_id
    and h.Code = e.country_code
    )
GO
