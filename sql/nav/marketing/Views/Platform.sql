CREATE view [marketing].[Platform]

as

select
    Platform.ID platformID,
    Platform.Platform,
    c.[Name] Country
from
    ext.Platform
join
    dbo.[UK$Country_Region] c
on
    (
        Platform.Country = c.Code
    )

union all

select
    999,
    'Undefined',
    'Undefined'
GO
