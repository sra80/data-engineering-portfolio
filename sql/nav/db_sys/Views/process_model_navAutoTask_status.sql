
create view [db_sys].[process_model_navAutoTask_status] as

select
	 m.model_name
	,m.table_name
	,m.partition_name
	,case when j.active_task_count > 0 then 1 else 0 end has_active_tasks
from
	db_sys.process_model_partitions m
left join
	(
		select
			 p.model_name
			,p.table_name
			,p.partition_name
			,sum(case when t.[Status] = 1 then 1 else 0 end) active_task_count
		from
			db_sys.process_model_navAutoTask_pairing p
		join
			[UK$AutoNAV Task] t
		on
			(
				p.navAutoTaskQueue = t.[AutoNAV Task Queue Code]
			and p.navAutoTaskID = t.ID
			)
		group by
			 p.model_name
			,p.table_name
			,p.partition_name
	) j
on
	(
		m.model_name = j.model_name
	and m.table_name = j.table_name
	and m.partition_name = j.partition_name
	)
GO
