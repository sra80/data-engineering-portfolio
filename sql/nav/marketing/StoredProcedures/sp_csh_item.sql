create or alter procedure marketing.sp_csh_item

as

set nocount on

declare @count int

declare @customer_id int

declare @u table (company_id int, customer_id int, [Document Type] int, [No_] nvarchar(20), [Doc_ No_ Occurrence] int, [Version No_] int)

insert into @u (company_id, customer_id, [Document Type], [No_], [Doc_ No_ Occurrence], [Version No_])
select
    h.company_id, h.customer_id, h.[Document Type], h.[No_], h.[Doc_ No_ Occurrence], h.[Version No_]
from
    ext.Sales_Header_Archive h
where
    (
        h.is_csh_processed = 0
    )

select
    @count = isnull(sum(1),0)
from
    @u

while @count > 0

begin

    select top 1
        @customer_id = customer_id
    from
        @u

    merge
        marketing.csh_item t
    using
        (
            select
                csh.customer_id,
                csh.item_id,
                csh._status,
                csh.scg_id,
                csh.date_start,
                csh.date_end,
                hashbytes('MD5',concat(csh._status, csh.date_start, csh.date_end)) _hash
            from
                marketing.fn_csh_item(@customer_id) csh
        ) s
    on
        (
            t.customer_id = s.customer_id
        and t.item_id = s.item_id
        and t.scg_id = s.scg_id
        )
    when matched and hashbytes('MD5',concat(t._status, t.date_start, t.date_end)) <> s._hash then
        update set
            t._status = s._status,
            t.date_start = s.date_start,
            t.date_end = s.date_end,
            t.updateTS = getutcdate()
    when not matched by target then 
        insert (customer_id, item_id, _status, scg_id, date_start, date_end)
        values (s.customer_id, s.item_id, s._status, s.scg_id, s.date_start, s.date_end)
    when not matched by source and t.customer_id = @customer_id then delete;

    update
        h
    set
        h.is_csh_processed = 1
    from
        ext.Sales_Header_Archive h
    join
        @u u
    on
        (
            h.company_id = u.company_id
        and h.[Document Type] = u.[Document Type]
        and h.[No_] = u.[No_]
        and h.[Doc_ No_ Occurrence] = u.[Doc_ No_ Occurrence]
        and h.[Version No_] = u.[Version No_]
        )
    where
        u.customer_id = @customer_id

    delete from
        @u
    where
        (
            customer_id = @customer_id
        )

    select
        @count = isnull(sum(1),0)
    from
        @u

end