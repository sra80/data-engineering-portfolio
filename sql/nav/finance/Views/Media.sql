
create   view finance.Media

as

select
    mc_ext.ID keyMedia,
    mc.[Code] [Media Code],
    mc.[Description] [Media Description],
	a.[Description] [Audience],
    case when left(a.Code,5) = 'STAFF' then 1 else 0 end is_staff
from
	[hs_consolidated].[Media Code] mc
join
    ext.Media_Code mc_ext
on
    (
        mc.company_id = mc_ext.company_id
    and mc.Code = mc_ext.media_code
    )
join
	[hs_consolidated].[Audience] a
on 
	(
        mc.company_id = a.company_id
    and mc.[Audience] = a.[Code]
    )
GO
