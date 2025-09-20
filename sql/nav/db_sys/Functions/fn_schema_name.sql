
CREATE function db_sys.fn_schema_name (@schema_id int) returns nvarchar(32)  as  begin  declare @schema_name nvarchar(32)  select @schema_name = [schema_name] from db_sys.schemas where [schema_id] = @schema_id  return @schema_name  end
GO
