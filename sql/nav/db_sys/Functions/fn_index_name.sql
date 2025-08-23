CREATE function [db_sys].[fn_index_name]
    (
        @object_id int,
        @index_id int
    )


returns nvarchar(255)

as

begin

declare @index_name nvarchar(255)

select @index_name = name from sys.indexes where object_id = @object_id and index_id = @index_id

return @index_name

end
GO
