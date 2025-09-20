create or alter function db_sys.fn_process_model_partitions_check
    (
        @model_name nvarchar(32),
        @table_name nvarchar(64),
        @partition_name nvarchar(64)
    )

returns table

as

return

select
    isnull(sum(1),0) process
from
    db_sys.process_model_partitions_procedure_pairing k
join
    db_sys.procedure_schedule s
on
    (
        k.procedureName = s.procedureName
    )
where
    (
        k.model_name = @model_name
    and k.table_name = @table_name
    and k.partition_name = @partition_name
    and s.process = 1
    )