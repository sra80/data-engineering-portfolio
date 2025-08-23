




CREATE view [finance].[Country]

as

select 
	 Code keyCountryCode
	,[Name] [Country] 
	,case 
		when Code in ('GB','GG','IM','JE','UK') then 'United Kingdom'
		when Code = 'AU' then 'Australia'
		when Code = 'IE' then 'Ireland'
		when Code = 'NZ' then 'New Zealand'
		when Code in ('AD','AL','AM','AT','AZ','BA','BE','BG','BY','CH','CY','CZ','DE','DK','EE','ES','FI','FO','FR','GE','GI','GL','GR','HR','HU','IS','IT','KG','KZ','LI','LT','LU','LV','MC','MD','ME','MK','MT','NL','NO','PL','PT','RO','SE','SI','SK','SM','TJ','TM','TR','UA','UZ','VA') then 'Europe'
		else 'Rest of World'
	end [Jurisdiction]
	,case 
		when Code in ('GB','GG','IM','JE','UK') then 'UK'
		when Code = 'AU' then 'AU'
		when Code = 'IE' then 'IE'
		when Code = 'NZ' then 'NZ'
		when Code in ('AD','AL','AM','AT','AZ','BA','BE','BG','BY','CH','CY','CZ','DE','DK','EE','ES','FI','FO','FR','GE','GI','GL','GR','HR','HU','IS','IT','KG','KZ','LI','LT','LU','LV','MC','MD','ME','MK','MT','NL','NO','PL','PT','RO','SE','SI','SK','SM','TJ','TM','TR','UA','UZ','VA') then 'EUR'
		else 'ROW'
	end [Jurisdiction Code]	
from 
	[dbo].[UK$Country_Region]

-- no longer required - ZZ is determined based on company within the model
union all

select
	 'ZZ'
	 ,'Unspecified'
	 ,'United Kingdom'
	 ,'UK'
GO
