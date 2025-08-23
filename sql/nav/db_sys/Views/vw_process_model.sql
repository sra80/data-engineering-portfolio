create or alter view [db_sys].[vw_process_model]

as

select
    pm.model_name [Model Name],
    case when pm.process_active = 1 then 'Yes' else 'No' end [Processing],
    case when pm.process_active = 0 and p.process = 1 then 'Yes' else 'No' end [Queued],
    case when pm.disable_process = 1 and pm.error_count < 3 then 'Yes' else 'No' end [Disabled],
    case when pm.disable_process = 1 and pm.error_count >= 3 then 'Yes' else 'No' end [Blocked],
    isnull(case when datediff(minute,pm.overdue_from,getutcdate()) < 50 or (pm.disable_process = 1 and pm.error_count < 3) then null else nullif(db_sys.fn_datediff_string(pm.overdue_from,getutcdate(),2),'@time_from is null') + ' overdue' end,'No') [Overdue],
    case when pm.disable_process = 1 and pm.error_count < 3 then 'Disabled' else db_sys.fn_datediff_string(lp.last_processed,getutcdate(),5) + ' ago' end [Last Processed],
    case when pm.disable_process = 1 and pm.error_count < 3 then 'Disabled' else case when nd.next_due > getutcdate() then concat('In ',db_sys.fn_datediff_string(getutcdate(),nd.next_due,5)) else case when nd.next_due < getutcdate() then 'Now' end end end [Next Due]
from
    db_sys.process_model pm
outer apply
    (
        select top 1
            process
        from
            db_sys.process_model_partitions pms
        where
            (
                pm.model_name = pms.model_name
            and pms.process = 1
            )
    ) p
outer apply
    (
        select top 1
            last_processed
        from
            db_sys.process_model_partitions xp
        where
            (
                pm.model_name = xp.model_name
            )
        order by
            last_processed desc
    ) lp
outer apply
    (
        select top 1
            next_due
        from
            db_sys.process_model_partitions xp
        where
            (
                pm.model_name = xp.model_name
            and xp.next_due is not null
            )
        order by
            next_due asc
    ) nd
GO
