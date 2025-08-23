
CREATE view [db_sys].[process_model_script]

as

select
	 r.model_name
	,r.model_url
	,case when p.process < p.total then model_part.script else model_all.script end model_script
    ,convert(nvarchar(36),newid()) place_holder
    ,isnull(last_runtime.runtime,9999) previous_runtime --runs model refresh/processing in order from shortest runtime to longest
    ,r.error_count
from
	db_sys.process_model r
join
	(select model_name, sum(case when process = 0 then 0 else 1 end) process, sum(1) total from db_sys.process_model_partitions group by model_name) p
on
	(
		r.model_name = p.model_name
	)
cross apply
	(
	select 
		(
			select
				 [root].[Type] 
				,[root].[CommitMode]
				,[root].[MaxParallelism]
				,[root].[RetryCount]
				,[Objects].[table] 
				,[Objects].[partition] 
			from
				(
					select 
						 model_name
						,'Full' [Type]
						,'transactional' [CommitMode]
						,MaxParallelism
						,2 [RetryCount]
					from 
						db_sys.process_model [root] 
					where 
						r.model_name = [root].model_name
				) [root] 
			left join
				(
                    select 
                        model_name,
                        table_name [table],
                        partition_name [partition] 
                    from 
                        db_sys.process_model_partitions 
                    where
                        (
                            process = 1
                        )

                    union

                    select 
                        model_name,
                        table_name [table],
                        partition_name [partition] 
                    from 
                        db_sys.process_model_partitions pmp
                    where
                        (
                            table_name = 'timestamp'
                        and model_name in (select model_name from db_sys.process_model_partitions xp where pmp.model_name = xp.model_name and xp.process = 1)
                        )
				) [Objects]
			on
				[root].model_name = [Objects].model_name
			for json auto, without_array_wrapper
		) script
	) model_part
cross apply
	(
	select 
		(
			select
				 [root].[Type] 
				,[root].[CommitMode]
				,[root].[MaxParallelism]
				,[root].[RetryCount]
			from
				(
					select 
						 model_name
						,'Full' [Type]
						,'transactional' [CommitMode]
						,MaxParallelism
						,2 [RetryCount]
					from 
						db_sys.process_model [root] 
					where 
						r.model_name = [root].model_name
				) [root] 
			for json auto, without_array_wrapper
		) script
	) model_all
left join
    (
        select
            l.eventName, datediff(second,l.eventUTCSTart,l.eventUTCEnd) runtime
        from
            (
                select max(ID) ID from db_sys.auditLog where eventType = 'Process Model' group by eventName
            ) r
        join
            db_sys.auditLog l
        on
            r.ID = l.ID
    ) last_runtime
on
    (
        r.model_name = last_runtime.eventName
    )
left join
	(
		select
			 p.model_name
			,sum(1) active_procedures
		from
			db_sys.process_model_procedure_pairing p
		join
			db_sys.procedure_schedule s
		on
			(
				p.procedureName = s.procedureName
			)
		where
			s.process_active = 1
		group by
			p.model_name
	) a
on
	r.model_name = a.model_name
where
    (
        r.process_active = 0
	and r.disable_process = 0
    and p.process > 0
	and isnull(a.active_procedures,0) = 0
    )
GO
