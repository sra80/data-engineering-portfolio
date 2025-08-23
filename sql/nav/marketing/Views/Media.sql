create or alter view [marketing].[Media]

as

select
    -1 key_media,
    'None' [Media Code],
    'Not set' [Media Description],
    'Not set' [Audience],
    0 valid,
    null offer_start,
    null offer_end,
    0 [Internal]

union all

select
    -2,
    'Invalid',
    'Invalid Media Code',
    'Invalid Media Code',
    0 valid,
    null offer_start,
    null offer_end,
    0 [Internal]

union all

select
    e.ID [Code],
    m.Code,
    case when left(a.Code,5) = 'STAFF' then ext.fn_media_code_staff_name(m.[Description]) else isnull(nullif(convert(nvarchar(64),m.Description),''),'Missing Code Description (' + m.[Code] + ')') end,
    isnull(nullif(convert(nvarchar(64),a.[Description]),''),'Missing Audience Description (' + a.[Code] + ')'),
    1,
    nullif(m.[Start Date],datefromparts(1753,1,1)),
    nullif(m.[End Date],datefromparts(1753,1,1)),
    case when left(a.Code,5) = 'STAFF' or a.Code = 'TEST' then 1 else 0 end
from
    hs_consolidated.[Media Code] m
join
    hs_consolidated.[Audience] a
on
    (
        m.company_id = a.company_id
    and m.[Audience] = a.[Code]
    )
join
    ext.Media_Code e
on
    (
        m.company_id = e.company_id
    and m.Code = e.media_code
    )
GO