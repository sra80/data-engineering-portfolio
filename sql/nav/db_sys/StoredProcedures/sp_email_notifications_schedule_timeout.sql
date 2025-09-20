create or alter procedure [db_sys].[sp_email_notifications_schedule_timeout]
    (
        @logic_app_identifier nvarchar(36) 
    )

as

set nocount on

update a set
    a.eventUTCEnd = l.eventUTCEnd,
    a.eventDetail = l.eventDetail
from
    db_sys.auditLog a
join
    (
select
    li.auditLog_ID,
    dateadd(ms,-100,lead(al.eventUTCStart) over (partition by li.logicApp_ID, ens_ID order by li.auditLog_ID)) eventUTCEnd,
    concat('Outcome: Failed, retry @',lead(li.auditLog_ID) over (partition by li.logicApp_ID, ens_ID order by li.auditLog_ID)) eventDetail
from
   db_sys.email_notifications_schedule_logicApp_identifier li
join
    db_sys.auditLog al
on
    (
        li.auditLog_ID = al.ID
    )
where
    (
        li.logicApp_ID = @logic_app_identifier
    )) l
on
    (
        a.ID = l.auditLog_ID
    )
where
    a.eventUTCEnd is null
GO
