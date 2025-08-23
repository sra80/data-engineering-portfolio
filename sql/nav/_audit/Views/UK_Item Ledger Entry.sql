CREATE view [_audit].[UK$Item Ledger Entry]

as

select
    d.*
from
    [dbo].[UK$Item Ledger Entry] d
cross apply
    _audit._1_date_range a
where
    (
        d.[Posting Date] >= a._date_from
    and d.[Posting Date] <= a._date_to
    )
GO
