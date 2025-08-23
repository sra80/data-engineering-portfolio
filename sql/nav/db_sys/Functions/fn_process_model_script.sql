create or alter function db_sys.fn_process_model_script
    (
        @model_name nvarchar(64),
        @offset_unit nvarchar(16) = 'hour',
        @offset_value int = 0
    )

returns table

as

return

(
    with s (script, table_name, partition_name, frequency_unit, frequency_value, procedure_dependents) as
        (

        select
            concat('{|',char(32),'"sequence":|',replicate(char(32),2),'{|',replicate(char(32),3),'"maxParallelism": ',MaxParallelism,',|',replicate(char(32),3),'"operations":|',replicate(char(32),4),'[|',replicate(char(32),5),'{|',replicate(char(32),6),'"refresh":|',replicate(char(32),7),'{|',replicate(char(32),8),'"type": "full",|',replicate(char(32),8),'"objects":|',replicate(char(32),9),'['),
            '***frame***',
            '***frame***',
            '***frame***',
            0,
            pd.procedure_dependents
        from
            db_sys.process_model
        cross apply
            (
                select
                    string_agg(pp.procedureName,', ') procedure_dependents
                from
                    db_sys.process_model_procedure_pairing pp
                where
                    (
                        process_model.model_name = pp.model_name
                    )
            ) pd
        where
            (
                model_name = @model_name
            )

        union all

        select
            concat(replicate(char(32),10),'{|',replicate(char(32),11),'"database": "',m.model_name,'",|',replicate(char(32),11),'"table": "',p.table_name,'",|',replicate(char(32),11),'"partition": "',p.partition_name,'"|',replicate(char(32),10),'}',case when row_number() over (order by p.table_name, p.partition_name) < sum(1) over () then ',' end),
            p.table_name, 
            p.partition_name, 
            p.frequency_unit, 
            p.frequency_value,
            pd.procedure_dependents
        from
            db_sys.process_model m
        join
            db_sys.process_model_partitions p
        on
            (
                m.model_name = p.model_name
            )
        cross apply
            (
                select
                    string_agg(pp.procedureName,', ') procedure_dependents
                from
                    db_sys.process_model_partitions_procedure_pairing pp
                where
                    (
                        p.model_name = pp.model_name
                    and p.table_name = pp.table_name
                    and p.partition_name = pp.partition_name
                    )
            ) pd
        where
            (
                db_sys.fn_set_process_flag(p.frequency_unit,p.frequency_value,p.last_processed,m.start_month,m.start_day,m.start_dow,m.start_hour,m.start_minute,m.end_month,m.end_day,m.end_dow,m.end_hour,m.end_minute,db_sys.fn_dateadd(@offset_unit,@offset_value,getutcdate())) = 1
            and m.model_name = @model_name
            )

        union all

        select concat(replicate(char(32),9),']|',replicate(char(32),7),'}|',replicate(char(32),5),'}|',replicate(char(32),4),']|',replicate(char(32),2),'}|}'),
        '***frame***',
        '***frame***',
        '***frame***',
        0,
        null

        )
        
    , w (output_select, script, table_name, partition_name, frequency_unit, frequency_value, procedure_dependents) as
        (
            select 
                case when (select sum(1) from s) > 1 and (select sum(1) from s) < 3 then 1 else 0 end,
                concat('nothing is due in the model ''',@model_name,''''),
                null,
                null,
                null,
                null,
                null

            union all

            select 
                case when (select sum(1) from s) = 1 then 1 else 0 end,
                concat('invalid model ''',@model_name,''''),
                null,
                null,
                null,
                null,
                null

            union all

            select
                case when (select sum(1) from s) > 3 then 1 else 0 end,
                script,
                table_name,
                partition_name,
                frequency_unit,
                frequency_value,
                procedure_dependents
            from
                s
        )

    select 
        x.value script,
        w.table_name,
        w.partition_name,
        w.frequency_unit,
        w.frequency_value,
        w.procedure_dependents
    from 
        w
    cross apply
        string_split(w.script,'|') x
    where
        (
            output_select = 1
        )

)