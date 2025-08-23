create or alter view [stock].[Country_Destination]

as

select
	e.ID country_id,
	h.[Name] Country,
	case h.[Delivery Zone] 
		when 'UK' then 'Domestic' 
		else 'International' 
	end Region,
	case when h.[Code] in
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
		then 'Yes' else 'No' end [EU Country],
	'N/A' [Local Code]
from 
	hs_consolidated.Country_Region h
join
    ext.Country_Region e
on
    (
        h.company_id = e.company_id
    and h.Code = e.country_code
    )

union all

select
	cr.ID counry_id,
	isnull(k_v.Country,'Unknown') Country,
	isnull(k_v.Region,'Unknown') Region,
	isnull(k_v.[EU Country],'No') [EU Country],
	isnull(convert(nvarchar(3),k_v.[Local Code]),'N/A') [Local Code]
from
	(
		select
			company_id,
			country_code 
		from
			ext.Country_Region

		except

		select
			company_id, [Code]
		from
			hs_consolidated.[Country_Region]
	) miss
join
	ext.Country_Region cr
on
	(
		miss.company_id = cr.company_id
	and miss.country_code = cr.country_code
	)
left join
	(
		select
			'EN' country_code,
			'England' Country,
			'Domestic' Region,
			'No' [EU Country],
			'EN' [Local Code]
		
		union all

		select
			'XI' country_code,
			'Northern Ireland' Country,
			'Domestic' Region,
			'No' [EU Country],
			'NI' [Local Code]

		union all

		select
			'CT' country_code,
			'Scotland' Country,
			'Domestic' Region,
			'No' [EU Country],
			'SC' [Local Code]

		union all

		select
			'WA' country_code,
			'Wales' Country,
			'Domestic' Region,
			'No' [EU Country],
			'WS' [Local Code]
	) k_v
on
	miss.country_code = k_v.country_code