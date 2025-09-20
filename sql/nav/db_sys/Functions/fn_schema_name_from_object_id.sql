create function db_sys.fn_schema_name_from_object_id
    (
        @object_id int
    )

returns nvarchar(64)

as

begin

declare @schema_name nvarchar(64)

select @schema_name = schema_name(schema_id) from sys.objects where object_id = @object_id

return @schema_name

end
GO
