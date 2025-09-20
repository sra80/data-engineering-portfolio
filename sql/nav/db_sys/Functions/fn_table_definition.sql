CREATE function [db_sys].[fn_table_definition]
    (
        @object_id int
    )

returns nvarchar(max)

as

begin

declare @object_name sysname, @sql nvarchar(max) = ''

select @object_name = concat('[',schema_name(schema_id),'].[',name,']') from sys.tables where object_id = @object_id

;with index_column as 
(
    select 
          ic.[object_id]
        ,ic.index_id
        ,ic.is_descending_key
        ,ic.is_included_column
        ,c.name
    from 
        sys.index_columns ic with (nowait)
    join 
        sys.columns c with (nowait) 
    on 
        (
            ic.[object_id] = c.[object_id] 
        and ic.column_id = c.column_id
        )
    where 
        (
            ic.[object_id] = @object_id
        )
),
fk_columns as 
(
     select 
          k.constraint_object_id
        ,cname = c.name
        ,rcname = rc.name
    from sys.foreign_key_columns k with (nowait)
    join sys.columns rc with (nowait) on rc.[object_id] = k.referenced_object_id and rc.column_id = k.referenced_column_id 
    join sys.columns c with (nowait) on c.[object_id] = k.parent_object_id and c.column_id = k.parent_column_id
    where k.parent_object_id = @object_id
)
select @sql = 'create table ' + @object_name + char(13) + '(' + char(13) + stuff((
    select char(9) + ',[' + c.name + '] ' +
        case when c.is_computed = 1
            then 'as ' + cc.[definition] 
            else lower(tp.name) + 
                case when tp.name in ('varchar','char','varbinary','binary','text')
                       then '(' + case when c.max_length = -1 then 'max' else convert(nvarchar(5),c.max_length) end + ')'
                     when tp.name in ('nvarchar','nchar','ntext')
                       then '(' + case when c.max_length = -1 then 'max' else convert(nvarchar(5),c.max_length / 2) end + ')'
                     when tp.name in ('datetime2','time2','datetimeoffset') 
                       then '(' + convert(nvarchar(5),c.scale) + ')'
                     when tp.name = 'decimal' 
                       then '(' + convert(nvarchar(5),c.[precision]) + ',' + convert(nvarchar(5),c.scale) + ')'
                    else ''
                end +
                case when c.collation_name is not null then ' collate ' + c.collation_name else '' end +
                case when c.is_nullable = 1 then ' null' else ' not null' end +
                case when dc.[definition] is not null then ' default' + dc.[definition] else '' end + 
                case when ic.is_identity = 1 then ' identity(' + convert(nvarchar,isnull(ic.seed_value,'0')) + ',' + convert(nvarchar(1),isnull(ic.increment_value,'1')) + ')' else '' end 
        end + char(13)
    from sys.columns c with (nowait)
    join sys.types tp with (nowait) on c.user_type_id = tp.user_type_id
    left join sys.computed_columns cc with (nowait) on c.[object_id] = cc.[object_id] and c.column_id = cc.column_id
    left join sys.default_constraints dc with (nowait) on c.default_object_id != 0 and c.[object_id] = dc.parent_object_id and c.column_id = dc.parent_column_id
    left join sys.identity_columns ic with (nowait) on c.is_identity = 1 and c.[object_id] = ic.[object_id] and c.column_id = ic.column_id
    where c.[object_id] = @object_id
    order by c.column_id
    for xml path(''),type).value('.','nvarchar(max)'),1,2,char(9) + ' ')
    + isnull((select char(9) + ',constraint [' + k.name + '] primary key (' + 
                    (select stuff((
                         select ', [' + c.name + '] ' + case when ic.is_descending_key = 1 then 'desc' else 'asc' end
                         from sys.index_columns ic with (nowait)
                         join sys.columns c with (nowait) on c.[object_id] = ic.[object_id] and c.column_id = ic.column_id
                         where ic.is_included_column = 0
                             and ic.[object_id] = k.parent_object_id 
                             and ic.index_id = k.unique_index_id     
                         for xml path(N''),type).value('.','nvarchar(max)'),1,2,''))
            + ')' + char(13)
            from sys.key_constraints k with (nowait)
            where k.parent_object_id = @object_id 
                and k.[type] = 'pk'),'') + ')'  + char(13)
    + isnull((select (
        select char(13) +
             'alter table ' + @object_name + ' with' 
            + case when fk.is_not_trusted = 1 
                then ' nocheck' 
                else ' check' 
              end + 
              ' add constraint [' + fk.name  + '] foreign key(' 
              + stuff((
                select ',[' + k.cname + ']'
                from fk_columns k
                where k.constraint_object_id = fk.[object_id]
                for xml path(''),type).value('.','nvarchar(max)'),1,2,'')
               + ')' +
              ' references [' + schema_name(ro.[schema_id]) + '].[' + ro.name + '] ('
              + stuff((
                select ',[' + k.rcname + ']'
                from fk_columns k
                where k.constraint_object_id = fk.[object_id]
                for xml path(''),type).value('.','nvarchar(max)'),1,2,'')
               + ')'
            + case 
                when fk.delete_referential_action = 1 then ' on delete cascade' 
                when fk.delete_referential_action = 2 then ' on delete set null'
                when fk.delete_referential_action = 3 then ' on delete set default' 
                else '' 
              end
            + case 
                when fk.update_referential_action = 1 then ' on update cascade'
                when fk.update_referential_action = 2 then ' on update set null'
                when fk.update_referential_action = 3 then ' on update set default'  
                else '' 
              end 
            + char(13) + 'alter table ' + @object_name + ' check constraint [' + fk.name  + ']' + char(13)
        from sys.foreign_keys fk with (nowait)
        join sys.objects ro with (nowait) on ro.[object_id] = fk.referenced_object_id
        where fk.parent_object_id = @object_id
        for xml path(N''),type).value('.','nvarchar(max)')),'')
    + isnull(((select
         char(13) + 'create' + case when i.is_unique = 1 then ' unique' else '' end 
                + ' nonclustered index [' + i.name + '] on ' + @object_name + ' (' +
                stuff((
                select ',[' + c.name + ']' + case when c.is_descending_key = 1 then ' desc' else ' asc' end
                from index_column c
                where c.is_included_column = 0
                    and c.index_id = i.index_id
                for xml path(''),type).value('.','nvarchar(max)'),1,2,'') + ')'  
                + isnull(char(13) + 'include (' + 
                    stuff((
                    select ',[' + c.name + ']'
                    from index_column c
                    where c.is_included_column = 1
                        and c.index_id = i.index_id
                    for xml path(''),type).value('.','nvarchar(max)'),1,2,'') + ')','')  + char(13)
        from sys.indexes i with (nowait)
        where i.[object_id] = @object_id
            and i.is_primary_key = 0
            and i.[type] = 2
        for xml path(''),type).value('.','nvarchar(max)')
    ),'')

return @sql

end
GO
