create or alter procedure db_sys.sp_trigger_rebuild

as

declare @sql nvarchar(max)

declare tr cursor for

select
    object_definition.object_definition
from
    (
        select distinct
            object_name
        from
            db_sys.objects o
        where
            (
                o.schema_id = 1
            and o.object_type = 'TR'
            and o.delete_date > datefromparts(1753,1,1)
            )
    ) tr_drop
left join
    (
        select
            o.object_name
        from
            db_sys.objects o
        where
            (
                o.schema_id = 1
            and o.object_type = 'TR'
            and delete_date is null
            )
    ) tr_exist
on
    (
        tr_drop.object_name = tr_exist.object_name
    )
cross apply
    (
        select top 1
            p.object_id,
            p.parent_object_id,
            p.delete_date
        from
            db_sys.objects p
        where
            (
                p.schema_id = 1
            and p.object_type = 'TR'
            and tr_drop.object_name = p.object_name
            )
        order by
            p.create_date desc
    ) tr_newest
join
    db_sys.objects parent_old
on
    (
        tr_newest.parent_object_id = parent_old.object_id
    and parent_old.delete_date > datefromparts(1753,1,1)
    )
join
    db_sys.objects parent_new
on
    (
        parent_old.schema_id = parent_new.schema_id
    and parent_old.object_name = parent_new.object_name
    and parent_new.delete_date is null
    )
cross apply
    (
        select top 1
            object_definition
        from
            db_sys.objects_change_control occ
        where
            (
                tr_newest.object_id = occ.object_id
            )
        order by
            occ.version_id desc
    ) object_definition
where
    (
        tr_exist.object_name is null
    and datediff(minute,tr_newest.delete_date,parent_old.delete_date) <= 60
    and abs(datediff(day,parent_old.delete_date,parent_new.create_date)) <= 5
    )

open tr

fetch next from tr into @sql

while @@fetch_status = 0

begin

    exec (@sql)

    fetch next from tr into @sql

end

close tr
deallocate tr
GO
