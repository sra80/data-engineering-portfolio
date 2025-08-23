create or alter view [db_sys].[vw_auditLog]

as

select top 20
    coalesce(l.ID,k.logicApp_ID,j.ID,replicate('0',33)) [Logic App ID],
    isnull(a.place_holder_session,0x0) [Elastic Job ID],
    a.ID [auditLog ID],
    a.eventType [Task Type],
    concat(a.eventName,case when d.parent_auditLog_ID > 0 then concat(' (',d.parent_auditLog_ID,')') else null end) [Task Name], 
    concat(case when eventUTCEnd is null then 'Running for ' else 'Processed in ' end,lower(db_sys.fn_datediff_string(eventUTCStart,isnull(eventUTCEnd,getutcdate()),default))) [Task Status],
    case when eventUTCEnd is null then case when db_sys.fn_divide(datediff(second,a.eventUTCStart,getutcdate()),n.avg,0) < 0.99 then db_sys.fn_divide(datediff(second,a.eventUTCStart,getutcdate()),n.avg,0) else 0.99 end else 1 end [Progress],
    datediff(second,isnull(eventUTCEnd,getutcdate()),getutcdate())_sort
from 
    db_sys.auditLog a
left join
    db_sys.auditLog_logicApp_identifier l
on
    (
        a.place_holder_session = l.sessionID
    )
left join
    db_sys.email_notifications_schedule_logicApp_identifier k
on
    (
        a.ID = k.auditLog_ID
    )
left join
    db_sys.auditLog_logicApp_identifier_model j
on
    (
        a.ID = j.auditLog_ID
    )
left join
    db_sys.auditLog_procedure_dependents d
on
    a.ID = d.auditLog_ID
left join
    db_sys.auditLog_dataFactory df
on
    (
        isnull(d.parent_auditLog_ID,a.ID) = df.auditLog_ID
    )
cross apply
    (
        select
            stdev(datediff(second,eventUTCStart,isnull(eventUTCEnd,eventUTCEnd))) stdev,
            avg(datediff(second,eventUTCStart,isnull(eventUTCEnd,eventUTCEnd))) avg
        from
            (select top 10000 * from db_sys.auditLog order by ID desc) x
        where
            (
                a.eventType = x.eventType
            and a.eventName = x.eventName
            )
    ) m
cross apply
    (
        select
            avg(datediff(second,eventUTCStart,isnull(eventUTCEnd,eventUTCEnd))) avg
        from
            (select top 10000 * from db_sys.auditLog order by ID desc) y
        where
            (
                a.eventType = y.eventType
            and a.eventName = y.eventName
            and datediff(second,eventUTCStart,isnull(eventUTCEnd,eventUTCEnd)) > m.avg - m.stdev
            and datediff(second,eventUTCStart,isnull(eventUTCEnd,eventUTCEnd)) < m.avg + m.stdev
            )
    ) n
 order by 
    a.is_active desc, 
    a.ID desc
GO
