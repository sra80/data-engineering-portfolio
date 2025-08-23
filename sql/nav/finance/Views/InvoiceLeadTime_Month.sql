CREATE view [finance].[InvoiceLeadTime_Month]

as

with cte as
    (
        select
            -23 key_InvoiceLeadTime

        union all

        select
            key_InvoiceLeadTime + 1
        from
            cte
        where
            key_InvoiceLeadTime < 71
    )

select
    key_InvoiceLeadTime,
    case key_InvoiceLeadTime when 0 then 'Same month' when -1 then 'Previous month' when 1 then 'Following month' else concat(abs(key_InvoiceLeadTime),' months',case when key_InvoiceLeadTime < 0 then ' before' else ' after' end) end [Invoice Lead Time (Month)]
from
    cte
GO
