create function db_sys.fn_FK_depends
        (
            @table_name nvarchar(64)
        )

returns table

as

return
select 
    concat(schema_name(o.schema_id),'.',o.name) parent_table,
    fs.name foreign_key 
from 
    sys.foreign_keys fs 
join 
    sys.objects o 
on 
    (
        fs.parent_object_id = o.object_id
    )
where 
    (
            referenced_object_id = 
                (
                    select 
                        object_id 
                    from 
                        sys.tables 
                    where 
                        (
                            schema_name(schema_id) = left(@table_name,charindex('.',@table_name)-1) 
                        and name = right(@table_name,len(@table_name)-charindex('.',@table_name))
                        )
                )
    )
GO
