create function db_sys.fn_index_info_indexName
    (

    )

returns nvarchar(7)

as

begin

declare @indexName nvarchar(7)

select @indexName = indexName from db_sys.index_info_indexName

return @indexName

end
GO
