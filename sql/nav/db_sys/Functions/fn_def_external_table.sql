create or alter function db_sys.fn_def_external_table
    (
        @object_id int,
        @replace_nonAlpaNumeric bit = 1
    )

returns nvarchar(max)

as

begin

declare @object_name sysname, @sql nvarchar(max) = ''

declare @schema_id int = (select schema_id from sys.objects where object_id = @object_id)

select @object_name = concat(quotename(isnull(schema_name(@schema_id),schema_name(schema_id))),'.',quotename(case when @replace_nonAlpaNumeric = 0 then name else db_sys.fn_replace_nonAlpaNumeric(name,default) end)) from sys.tables where object_id = @object_id

select @sql = concat('create external table ',@object_name,char(13),'(',char(13)) + stuff((
    select char(9) + ',[' + case when @replace_nonAlpaNumeric = 0 then c.name else db_sys.fn_replace_nonAlpaNumeric(c.name,default) end + '] ' +
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

    set @sql += 'with (data_source = [nav_prod_repl]);'

return @sql

end
GO
