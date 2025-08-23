CREATE procedure db_sys.sp_index_maintenance
 
as
 
declare @table nvarchar(255), @index nvarchar(7), @sql nvarchar(max)
 
declare x cursor for
select
    concat('[',schema_name(objects.schema_id),'].[',objects.name,']'),
    indexes.name 
from
    sys.dm_db_index_usage_stats
join 
    sys.objects 
on 
    (
        dm_db_index_usage_stats.object_id = objects.object_id
    )
join 
    sys.indexes
on
    (
        indexes.index_id = dm_db_index_usage_stats.index_id 
    and dm_db_index_usage_stats.object_id = indexes.object_id
    )
where
    (
        indexes.is_primary_key = 0 --This line excludes primary key constarint
    and indexes.is_unique = 0 --This line excludes unique key constarint
    and dm_db_index_usage_stats.user_updates <> 0 -- This line excludes indexes SQL Server hasn’t done any work with
    and dm_db_index_usage_stats. user_lookups = 0
    and dm_db_index_usage_stats.user_seeks = 0
    and dm_db_index_usage_stats.user_scans = 0
    and objects.schema_id in (select schema_id from sys.schemas where principal_id = 1) --('dbo','ext')
    and indexes.name in (select indexName collate database_default from db_sys.index_info where datediff(day,createdDate,getutcdate()) > 60)
    )
 
open x
 
fetch next from x into @table, @index
 
while @@fetch_status = 0
 
begin
 
set @sql = concat('update db_sys.index_info set info = concat(info,''. Index deleted as not in use 60+ days after creation.''), deletedBy = lower(system_user), deletedDate = getutcdate() where indexName = ''',@index,'''',char(10))
 
set @sql += concat('drop index ',@index,' on ',@table)
 
exec (@sql)
 
fetch next from x into @table, @index
 
end
 
close x
deallocate x
GO
