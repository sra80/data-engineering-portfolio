create view db_sys.vw_index_info_missing

as

select object_name(i.object_id) tableName, i.[Name] indexName from sys.indexes i left join db_sys.index_info f on i.name = f.indexName collate database_default where patindex('IX__[0-9A-Z][0-9A-Z][0-9A-Z]',name) > 0 and f.indexName is null
GO
