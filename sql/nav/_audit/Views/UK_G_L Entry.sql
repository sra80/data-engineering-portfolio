CREATE view _audit.[UK$G_L Entry]

as

select
    *
from
    [dbo].[UK$G_L Entry] d
cross apply
    _audit._1_date_range a
where
    (
        d.[Posting Date] >= a._date_from
    and d.[Posting Date] <= a._date_to
    )
GO
