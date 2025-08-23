CREATE view _audit.[UK$Detailed Vendor Ledg_ Entry]

as

select
    *
from
    [dbo].[UK$Detailed Vendor Ledg_ Entry] d
cross apply
    _audit._1_date_range a
where
    (
        d.[Posting Date] >= a._date_from
    and d.[Posting Date] <= a._date_to
    )
GO
