
create   view [finance].[SalesInvoices_Country]

as

select 
	 e.ID keyCountryCode
	,h.[Name] [Country] 
	,case 
		when h.Code in ('GB','GG','IM','JE','UK') then 'United Kingdom'
		when h.Code = 'AU' then 'Australia'
		when h.Code = 'IE' then 'Ireland'
		when h.Code = 'NZ' then 'New Zealand'
		when h.Code in ('AD','AL','AM','AT','AZ','BA','BE','BG','BY','CH','CY','CZ','DE','DK','EE','ES','FI','FO','FR','GE','GI','GL','GR','HR','HU','IS','IT','KG','KZ','LI','LT','LU','LV','MC','MD','ME','MK','MT','NL','NO','PL','PT','RO','SE','SI','SK','SM','TJ','TM','TR','UA','UZ','VA') then 'Europe'
		else 'Rest of World'
	end [Jurisdiction]	
from 
	[hs_consolidated].[Country_Region] h
join
    ext.Country_Region e
on
    (
        h.company_id = e.company_id
    and h.Code = e.country_code
    )

union all

select
	 -1
	 ,'Unspecified'
	 ,'United Kingdom'
GO
