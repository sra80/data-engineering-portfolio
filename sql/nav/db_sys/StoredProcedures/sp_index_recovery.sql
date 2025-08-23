create or alter procedure db_sys.sp_index_recovery
    (
        @date_delete date = null --recover indexes dropped on this date, defaults to first of current month
    )

as

set nocount on

if @date_delete is null set @date_delete = dateadd(day,1,eomonth(getutcdate(),-1))

declare @indexName nvarchar(64),  @script nvarchar(max)

while (select sum(1) from db_sys.index_info h left join sys.indexes i on h.indexName = i.[name] collate database_default where right(h.info,116) = 'Inserted by sp db_sys.sp_index_info as missing from this table. Index deleted as not in use 60+ days after creation.' and convert(date,deletedDate) = @date_delete and i.name is null and h.errorBlock = 0) > 0

begin

    select top 1 @indexName = indexName, @script = script from db_sys.index_info h left join sys.indexes i on h.indexName = i.[name] collate database_default where right(h.info,116) = 'Inserted by sp db_sys.sp_index_info as missing from this table. Index deleted as not in use 60+ days after creation.' and convert(date,deletedDate) = @date_delete and i.name is null and h.errorBlock = 0

    exec (@script)

    update db_sys.index_info set info = concat(info,'Recreated on ',getutcdate(),' by ',lower(system_user),'.'), updatedBy = lower(system_user), updatedDate = getutcdate(), deletedBy = null, deletedDate = null where indexName = @indexName

    insert into db_sys.recreate_missing_indexes_log (indexName) values (@indexName)

end