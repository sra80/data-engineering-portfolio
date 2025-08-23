create or alter view db_sys.vw_procedure_schedule

as

with h as
    (
        select
            procedureName_parent procedureName_super,
            procedureName_child,
            0 heirarchy
        from
            db_sys.procedure_schedule_pairing
        where
            (
                procedureName_parent not in (select procedureName_child from db_sys.procedure_schedule_pairing)
            )

        union all

        select
            h.procedureName_super,
            y.procedureName_child,
            h.heirarchy + 1
        from
            h
        join
            db_sys.procedure_schedule_pairing y
        on
            (
                h.procedureName_child = y.procedureName_parent
            )
    )

select
    isnull(f.model_name,p.model_name) [Model Name],
    h_ps.procedureName [Procedure Name],
    case when h_ps.process_active = 1 then 'Yes' else 'No' end [Processing],
    case when (h_ps.process_active = 0 and h_ps.process = 1) or (j.process_active = 0 and j.process = 1) then 'Yes' else 'No' end [Queued],
    case when (h_ps.schedule_disabled = 1 or h_ps.frequency_unit = 'once') and h_ps.error_count < 3 then 'Yes' else 'No' end [Disabled],
    case when h_ps.schedule_disabled = 1 and h_ps.error_count >= 3 then 'Yes' else 'No' end [Blocked],
    isnull(case when datediff(minute,h_ps.overdue_from,getutcdate()) < 50 or (h_ps.schedule_disabled = 1 and h_ps.error_count < 3) then null else nullif(db_sys.fn_datediff_string(h_ps.overdue_from,getutcdate(),2),'@time_from is null') + ' overdue' end,'No') [Overdue],
    case when h_ps.schedule_disabled = 1 and h_ps.error_count < 3 then 'Disabled' else db_sys.fn_datediff_string(h_ps.last_processed,getutcdate(),5) + ' ago' end [Last Processed],
    case when h_ps.schedule_disabled = 1 then case when h_ps.error_count < 3 then 'Disabled' else 'Blocked' end else case when h_ps.frequency_unit = 'once' then 'Only run once' else case when next_due.next_due > getutcdate() then concat('In ',db_sys.fn_datediff_string(getutcdate(),next_due.next_due,5)) else case when next_due.next_due < getutcdate() then case when m.process_active = 1 then 'Model Processing' else 'Now' end end end end end [Next Due]
from
    db_sys.procedure_schedule h_ps
left join
    h
on
    (
        h_ps.procedureName = h.procedureName_child
    )
left join
    db_sys.process_model_procedure_pairing f
on
    (
        h_ps.procedureName = f.procedureName
    or  h.procedureName_super = f.procedureName
    )
outer apply
    (
        select top 1
            xp.next_due,
            xl.process_active
        from
            db_sys.process_model_partitions xp
        join
            db_sys.process_model xl
        on
            (
                xp.model_name = xl.model_name
            )
        where
            (
                f.model_name = xp.model_name
            and xp.next_due is not null
            )
        order by
            xp.next_due
    ) m
outer apply
    (
        select top 1
            d.model_name,
            d.next_due
        from
            db_sys.process_model_partitions d
        join
            db_sys.process_model_partitions_procedure_pairing l
        on
            (
                d.model_name = l.model_name
            and d.table_name = l.table_name
            and d.partition_name = l.partition_name
            )
        where
            (
                (
                    l.procedureName = h_ps.procedureName
                or  l.procedureName = h.procedureName_super
                )
            and d.next_due is not null
            )
        order by
            d.next_due
    ) p
outer apply
    (
        select top 1
            q.process_active,
            q.process,
            q.next_due
        from
            db_sys.procedure_schedule q
        where
            (
                q.procedureName = h.procedureName_super
            and q.next_due is not null
            )
        order by
            q.next_due
    ) j
cross apply
    (
        select 
            (select min(nd.nd) from (values(h_ps.next_due),(m.next_due),(p.next_due),(j.next_due)) as nd(nd)) next_due
    ) next_due