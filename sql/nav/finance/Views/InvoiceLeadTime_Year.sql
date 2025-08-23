CREATE view [finance].[InvoiceLeadTime_Year]

as

with cte as
    (
        select
            -2 key_InvoiceLeadTime

        union all

        select
            key_InvoiceLeadTime + 1
        from
            cte
        where
            key_InvoiceLeadTime < 3
    )

select
    key_InvoiceLeadTime,
    case key_InvoiceLeadTime when 0 then 'Same year' when -1 then 'Previous year' when 1 then 'Following year' else concat(abs(key_InvoiceLeadTime),' years',case when key_InvoiceLeadTime < 0 then ' before' else ' after' end) end [Invoice Lead Time (Year)]
from
    cte
GO
