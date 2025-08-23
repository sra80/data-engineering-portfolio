create or alter procedure marketing.sp_csh_item_range

as

set nocount on

declare @count int

declare @c table (company_id int, cus_code nvarchar(20), customer_id int)

insert into @c (company_id, cus_code, customer_id)
select distinct top 100
    company_id,
    [Sell-to Customer No_],
    customer_id
from
    ext.Sales_Header_Archive
where
    (
        is_csh_processed = 0
    )

select
    @count = isnull(sum(1),0)
from
    @c

while @count > 0

begin

    merge
        marketing.csh_item_range t
    using
        (
            select distinct
                csh.customer_id,
                csh.range_id,
                csh._status,
                csh.scg_id,
                csh.date_start,
                csh.date_end,
                hashbytes('MD5',concat(csh._status, csh.date_start, csh.date_end)) _hash
            from
                @c c
            cross apply
                marketing.fn_csh_item_range(c.customer_id) csh
        ) s
    on
        (
            t.customer_id = s.customer_id
        and t.range_id = s.range_id
        and t.scg_id = s.scg_id
        )
    when matched and hashbytes('MD5',concat(t._status, t.date_start, t.date_end)) <> s._hash then
        update set
            t._status = s._status,
            t.date_start = s.date_start,
            t.date_end = s.date_end,
            t.updateTS = getutcdate()
    when not matched by target then 
        insert (customer_id, range_id, _status, scg_id, date_start, date_end)
        values (s.customer_id, s.range_id, s._status, s.scg_id, s.date_start, s.date_end)
    when not matched by source and t.customer_id in (select customer_id from @c) then delete;

    update
        h
    set
        h.is_csh_processed = 1
    from
        ext.Sales_Header_Archive h
    join
        @c c
    on
        (
            h.company_id = c.company_id
        and h.[Sell-to Customer No_] = c.cus_code
        )

    update
        f
    set
        f.is_csh_processed = 1
    from
        @c c
    join
        hs_identity.Customer d
    on
        (
            c.customer_id = d.customer_id
        )
    join
        hs_identity_link.Customer_NAVID n
    on
        (
            d.nav_id = n.ID
        )
    left join
        @c e
    on
        (
            n.company_id = e.company_id
        and n.nav_code = e.cus_code
        )
    join
        ext.Sales_Header_Archive f
    on
        (
            n.company_id = f.company_id
        and n.nav_code = f.[Sell-to Customer No_]
        )
    where
        (
            e.company_id is null
        and e.cus_code is null
        )

    delete from @c

    insert into @c (company_id, cus_code, customer_id)
    select distinct top 100
        company_id,
        [Sell-to Customer No_],
        customer_id
    from
        ext.Sales_Header_Archive
    where
        (
            is_csh_processed = 0
        )

    select
        @count = isnull(sum(1),0)
    from
        @c

end