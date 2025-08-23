CREATE function [db_sys].[fn_object_definition]
     (
         @object_name nvarchar(64),
         @rollback_version int = 0,
         @split_char nvarchar(1) = null
     )
 
returns table
 
return

(
    with 
        occ as
            (
                select [object_definition], [version_id], [modify_date], max(version_id) over () - version_id rollback_version from db_sys.objects_change_control where object_id = db_sys.fn_object_id(@object_name)
            ),
        mod as
            (
                select 'modify_date: ' + char(9) + convert(nvarchar,modify_date,113) + ' (UTC)' txt from occ where rollback_version = @rollback_version
            ),
        del as
            (
                select 'delete_date: ' + char(9) + convert(nvarchar,delete_date,113) + ' (UTC)' txt from db_sys.objects where object_id = db_sys.fn_object_id(@object_name)
            )

    select '/**********' _definition

    union all

    select 'version_id: ' + char(9) + convert(nvarchar,version_id) from occ where rollback_version = @rollback_version

    union all

    select isnull((select txt from del),(select txt from mod))

    union all

    select '**********/'

    union all

    select ''

    union all

    select 
        left(ss.value,len(ss.value)-case when ascii(right(ss.value,1)) = 10 then 1 else 0 end)
    from 
        occ 
    cross apply 
        string_split(occ.object_definition,isnull(@split_char,char(13))) ss
    where
        (
            rollback_version = @rollback_version
        )
)
GO
