create or alter function db_sys.fn_Lookup
    (
        @table_name nvarchar(128),
        @column_name nvarchar(128),
        @key_value int
    )

returns nvarchar(128)

as

begin

declare @return_value nvarchar(128)

set @table_name = replace(replace(@table_name,'[',''),']','')

set @table_name = right(@table_name,len(@table_name)-charindex(char(36),@table_name))

set @table_name = right(@table_name,len(@table_name)-charindex(char(46),@table_name))

set @column_name = replace(replace(@column_name,'[',''),']','')

select
    @return_value = _value
from
    db_sys.Lookup
where
    (
        Lookup.tableName = @table_name
    and Lookup.columnName = @column_name
    and Lookup._key = @key_value
    )

return @return_value

end