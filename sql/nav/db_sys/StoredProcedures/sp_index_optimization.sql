
CREATE procedure [db_sys].[sp_index_optimization]

as

set nocount on

declare @object_id int, @index_id int, @place_holder uniqueidentifier, @auditLog_ID int, @avg_fragmentation_in_percent float, @s nvarchar(max)

select @place_holder = place_holder from db_sys.procedure_schedule where procedureName = 'db_sys.sp_index_optimization'

select @auditLog_ID = ID from db_sys.auditLog where try_convert(uniqueidentifier,eventDetail) = @place_holder

declare @t table (object_id int, index_id int, avg_fragmentation_in_percent float)

insert into @t (object_id, index_id, avg_fragmentation_in_percent)
select top 50
    x.object_id, 
    x.index_id,
    x.avg_fragmentation_in_percent
from 
    sys.dm_db_index_physical_stats(default,default,default,default,default) x
where
    x.avg_fragmentation_in_percent > 30
order by
    x.avg_fragmentation_in_percent desc

while (select isnull(sum(1),0) from @t) > 0

begin

    select top 1 @object_id = object_id, @index_id = index_id, @avg_fragmentation_in_percent = avg_fragmentation_in_percent from @t

        if (object_name(@object_id)) is not null and db_sys.fn_index_name(@object_id, @index_id) is not null

            begin

                set @s = concat('alter index [',db_sys.fn_index_name(@object_id, @index_id),'] on [',db_sys.fn_schema_name_from_object_id(@object_id),'].[',object_name(@object_id),'] rebuild')

                        begin try

                            exec (@s)

                            insert into db_sys.index_optimization (object_id, index_id, instance, _rebuild, auditLog_ID, avg_fragmentation_in_percent)
                            values (@object_id, @index_id, isnull((select max(instance) from db_sys.index_optimization where object_id = @object_id and index_id = @index_id),-1)+1,1,@auditLog_ID, @avg_fragmentation_in_percent)

                        end try

                        begin catch

                        insert into db_sys.index_optimization_error (object_id, index_id, instance, _rebuild, auditLog_ID, avg_fragmentation_in_percent, error_message)
                        values (@object_id, @index_id, isnull((select max(instance) from db_sys.index_optimization_error where object_id = @object_id and index_id = @index_id),-1)+1,1,@auditLog_ID, @avg_fragmentation_in_percent, error_message())

                        end catch

            end

        delete from @t where object_id = @object_id and index_id = @index_id

end
GO
