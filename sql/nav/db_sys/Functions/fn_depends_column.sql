create function db_sys.[fn_depends_column]
    (
        @column_name nvarchar(64)

    )

returns table

as

return
select 
    concat('[',s.name,'].[',o.name,']') _dependent,
    o.type_desc object_type
from
    db_sys.objects_change_control occ
cross apply
    (
        select top 1 object_id, version_id from db_sys.objects_change_control x where occ.object_id = x.object_id order by x.version_id desc
    ) _current
join
    sys.objects o
on
    occ.object_id = o.object_id
join
    sys.schemas s
on
    (
        o.schema_id = s.schema_id
    )
where
    (
        occ.version_id = _current.version_id
    and occ.object_definition like concat('%',@column_name,'%')
    )
GO
