CREATE procedure [db_sys].[sp_index_info]

as

merge db_sys.index_info as t
using
    (
        select 
            i.name indexName  
            ,'['+schema_name(schema_id)+'].['+object_name(i.object_id)+']' tableName
            ,0 projectID
            ,'CREATE'
                + case when i.is_unique = 1 then ' UNIQUE ' else ' ' end + i.type_desc + ' INDEX ' 
                + i.name + ' ON ' 
                + '['+schema_name(schema_id)+'].['+object_name(i.object_id)+']'  collate database_default + ' (' + indexed_columns.i + ')'
                + case when included_columns.i is not null then ' INCLUDE (' + included_columns.i + ')' else '' end
              /*where clause ()*/
              + case when i.has_filter = 1 then ' WHERE '   + i.filter_definition else '' end
                 script
            ,'Inserted by sp db_sys.sp_index_info as missing from this table' info
        from 
            sys.indexes i 
        join
            sys.tables t
        on
            (
                i.object_id = t.object_id
            )
        left join 
            db_sys.index_info f 
        on 
            (
                i.name = f.indexName collate database_default
            )
        cross apply
            (
                select stuff((select
                    ',['+c.name+']' + case when ic.is_descending_key = 0 then '' else ' DESC' end
                from
                    sys.index_columns ic
                join
                    sys.columns c
                on
                    ic.object_id = c.object_id
                and ic.column_id = c.column_id
                where
                    i.index_id = ic.index_id
                and i.object_id = ic.object_id --
                and ic.is_included_column = 0
                for xml path ('')),1,1,'') i
            ) indexed_columns
        cross apply
            (
                select stuff((select
                    ',['+c.name+']'
                from
                    sys.index_columns ic
                join
                    sys.columns c
                on
                    ic.object_id = c.object_id
                and ic.column_id = c.column_id
                where
                    i.index_id = ic.index_id
                and i.object_id = ic.object_id --
                and ic.is_included_column = 1
                for xml path ('')),1,1,'') i
            ) included_columns
        where 
            (
                patindex('IX__[0-9A-Z][0-9A-Z][0-9A-Z]',i.name) > 0 
            )
    ) as s
on
    (
        t.indexName = s.indexName collate database_default
    )
when not matched by target then
    insert (indexName,tableName,projectID,script,info)
    values (s.indexName,s.tableName,s.projectID,s.script,s.info)
when matched and (s.script != t.script) then
    update set 
        t.script = s.script,
        t.updatedBy = lower(suser_sname()),
        t.updatedDate = getutcdate();
GO
