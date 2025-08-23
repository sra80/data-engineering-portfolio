create view _audit.[UK$Vendor Ledger Entry]

as

select
    *
from
    [dbo].[UK$Vendor Ledger Entry] d
cross apply
    _audit._1_date_range a
where
    (
        d.[Posting Date] >= a._date_from
    and d.[Posting Date] <= a._date_to
    )
GO
