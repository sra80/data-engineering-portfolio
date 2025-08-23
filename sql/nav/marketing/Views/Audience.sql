CREATE view marketing.Audience

as

select
    media_code,
    'Invalid Code (' + media_code + ')' Audience,
    0 Valid,
    null offer_start,
    null offer_end
from
    (
        select
            o.[Media Code] media_code
        from
            (select [Media Code] from ext.Sales_Header union all select [Media Code] from ext.Sales_Header_archive) o
        left join
            [UK$Media Code] m
        on
            o.[Media Code] = m.Code
        where
            (
                m.Code is null
            and len(o.[Media Code]) > 0
            )
        group by
            o.[Media Code]
        order by 
            sum(1) desc
        offset 0 rows
        fetch next 50 rows only
    ) x

union all

select
    m.[Code],
    a.[Description],
    1,
    nullif(m.[Start Date],datefromparts(1753,1,1)),
    nullif(m.[End Date],datefromparts(1753,1,1))
from
    [UK$Media Code] m
join
    [UK$Audience] a
on
    (
        m.[Audience] = a.[Code]
    )
GO
