CREATE view _audit._3_check

as

select top 100 percent
    *, concat('_audit.[',substring(_list,charindex('.',_list)+2,len(_list)-charindex('.',_list)-2),']') view_name,
    case when substring(_list,charindex('.',_list)+2,len(_list)-charindex('.',_list)-2) collate database_default in
        (
        select
            name
        from
            sys.views
        where
            schema_name(schema_id) = '_audit'
        )
    then 'Yes' else 'No' end _done
from 
    _audit._0_table_list 
order by
    4
GO
