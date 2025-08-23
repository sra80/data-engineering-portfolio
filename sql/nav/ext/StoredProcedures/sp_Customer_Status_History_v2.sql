create or alter procedure ext.sp_Customer_Status_History_v2

as

set nocount on

declare @customer_id int, @error_message nvarchar(max)

declare x cursor for
select distinct
    hc.customer_id
from
    hs_consolidated.[Customer] c
join
    hs_identity_link.Customer_NAVID n
on
    (
        c.company_id = n.company_id
    and c.No_ = n.nav_code
    )
join
    hs_identity.Customer hc
on
    (
        n.ID = hc.nav_id
    )
where
    (
        c.[Customer Type] = 'NZ_WEB'
    )

open x

fetch next from x into @customer_id

while @@fetch_status = 0

begin

    merge ext.Customer_Status_History_v2 t
    using (select @customer_id customer_id, date_start, date_end, status_id, last_order from ext.fn_Customer_Status_History_v2(@customer_id)) s
    on (t.customer_id = s.customer_id and t.date_start = s.date_start)
    when matched and (t.date_end != s.date_end or (t.date_end is null and s.date_end is not null) or t.status_id != s.status_id or t.last_order != s.last_order) then
    update set
        t.date_end = s.date_end,
        t.status_id = s.status_id,
        t.last_order = s.last_order,
        t.revTS = sysdatetime()
    when not matched by target then insert (customer_id, date_start, date_end, status_id, last_order)
    values (s.customer_id, s.date_start, s.date_end, s.status_id, s.last_order);

fetch next from x into @customer_id

end

close x
deallocate x
GO
