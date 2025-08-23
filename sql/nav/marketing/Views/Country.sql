
create   view [marketing].[Country]

as

select 
	 e.ID ord_dest_cou
	,h.[Name] Country
	,case h.[Delivery Zone] 
		when 'UK' then 'Domestic' 
		else 'International' 
	end Region
	,case when h.[Code] in
		(
			 'AT'
			,'BE'
			,'BG'
			,'HR'
			,'CY'
			,'CZ'
			,'DK'
			,'EE'
			,'FI'
			,'FR'
			,'DE'
			,'GR'
			,'HU'
			,'IE'
			,'IT'
			,'LV'
			,'LT'
			,'LU'
			,'MT'
			,'NL'
			,'PL'
			,'PT'
			,'RO'
			,'SK'
			,'SI'
			,'ES'
			,'SE'
		)
		then 'Yes' else 'No' end [EU Country] 
from 
	hs_consolidated.Country_Region h
join
    ext.Country_Region e
on
    (
        h.company_id = e.company_id
    and h.Code = e.country_code
    )
GO
