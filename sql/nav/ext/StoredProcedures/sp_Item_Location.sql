create or alter procedure ext.sp_Item_Location

as

set nocount on

declare @t table (item_id int, location_id int)

declare @count int = 1, @item_id int, @location_id int

insert into @t (item_id, location_id)
select
    i.ID, l.ID
from
    ext.Item i
join
    hs_consolidated.Item ii
on
    (
        i.company_id = ii.company_id
    and i.No_ = ii.No_
    )
outer apply
    (
        select top 1
            sales_update
        from
            ext.Item_Location il
        where
            (
                il.item_id = i.ID
            )
    ) il
cross apply
    (
        select
            ID
        from
            ext.Location
        where
            (
                distribution_loc = 1
            or  default_loc = 1
            )
    ) l
where
    (
        i.lastOrder >= dateadd(day,-182,getutcdate())
    and ii.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
    and
        (
            il.sales_update is null
        or  dateadd(month,1,db_sys.fomonth(il.sales_update)) < getutcdate()
        )
    )

select
    @count = isnull(sum(1),0)
from
    @t

while @count > 0

begin

    select top 1
        @item_id = item_id,
        @location_id = location_id
    from
        @t

    merge ext.Item_Location t
    using
        (
            select
                @item_id item_id,
                @location_id location_id,
                sales.sales_total,
                sales.sales_single,
                sales.sales_repeat
            from
                ext.fn_Item_Location_avg_sales(@item_id, @location_id) sales
        ) s
    on
        (
            t.item_id = s.item_id
        and t.location_id = s.location_id
        )
    when not matched by target then
        insert (item_id, location_id, sales_total, sales_single, sales_repeat)
        values (s.item_id, s.location_id, s.sales_total, s.sales_single, s.sales_repeat)
    when matched then update set
        t.sales_total = s.sales_total,
        t.sales_single = s.sales_single,
        t.sales_repeat = s.sales_repeat,
        t.sales_update = getutcdate();

    delete from @t where item_id = @item_id and location_id = @location_id
    
    set @count -= 1

end