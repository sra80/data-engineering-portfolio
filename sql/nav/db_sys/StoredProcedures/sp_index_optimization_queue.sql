CREATE procedure [db_sys].[sp_index_optimization_queue]

as

insert into db_sys.index_optimization_queue (object_id, index_id)
select 
    x.object_id, 
    x.index_id 
from 
    sys.dm_db_index_physical_stats(default,default,default,default,default) x
left join
    db_sys.index_optimization_queue q
on
    (
        x.object_id = q.object_id
    and x.index_id = q.index_id
    )
where 
    (
        x.avg_fragmentation_in_percent > 30
    and q.object_id is null
    and q.index_id is null
    and object_name(x.object_id) is not null
    )
order by
    avg_fragmentation_in_percent desc
GO
