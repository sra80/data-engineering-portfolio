create or alter procedure [db_sys].[sp_email_notifications_schedule_error_handling]
    (
        @place_holder_session uniqueidentifier,
        @error_message nvarchar(max),
        @logic_app_identifier nvarchar(36) = null
    )

as

set nocount on

declare @place_holder uniqueidentifier, @ID int, @auditLog_ID int, @email_subject nvarchar(255), @email_bodyIntro nvarchar(max), @error_count int, @schedule_disabled bit = 0

select @ID = ID, @email_subject = email_subject, @error_count = error_count, @place_holder = place_holder from db_sys.email_notifications_schedule where place_holder_session = @place_holder_session and is_processing = 1

select @auditLog_ID = ID from db_sys.auditLog where upper(eventDetail) = upper(convert(nvarchar(36),@place_holder))

insert into db_sys.email_notifications_schedule_errorLog (schedule_ID, auditLog_ID, error_message)
values (@ID, @auditLog_ID, @error_message)

set @error_count += 1

set @email_bodyIntro = 'An error prevented the trigger associated with scheduled e-mail notication with subject ' + @email_subject + ' (sp_email_notifications_schedule ID: ' + convert(nvarchar,@ID) + ') from completing successfully. The error message received was <i>' + @error_message + '</i>. The auditLog_ID is ' + convert(nvarchar,@auditLog_ID) + '.'

if @error_count >= 3

    begin 
                        
        set @schedule_disabled = 1
                        
        set @email_bodyIntro += '<p style="color:red">As the last ' + convert(nvarchar,@error_count) + ' attempts have failed, this scheduled e-mail has been disabled.</p><p>Once the issue has been identified and resolved, please re-enable it in db_sys.email_notifications_schedule.'

    end

exec db_sys.sp_email_notifications @subject = 'Error Sending Scheduled E-Mail Notification', @bodyIntro = @email_bodyIntro, @auditLog_ID = @auditLog_ID, @is_team_alert = 1, @tnc_id = 6

exec db_sys.sp_auditLog_end @eventDetail='Outcome: Failed',@placeHolder=@place_holder

update db_sys.email_notifications_schedule set is_processing = 0, is_queued = 0, error_count = error_count + 1 where ID = @ID

update db_sys.email_notifications_schedule set schedule_disabled = 1 where ID = @ID and error_count >= 3

--auditLog cleanup
declare @t table (auditLog_ID int, eventUTCEnd datetime2(1))

insert into @t (auditLog_ID, eventUTCEnd)
select 
    l.auditLog_ID,
    isnull(dateadd(ms,-100,lead(a.eventUTCStart) over (order by a.eventUTCStart)),getutcdate())
from
    db_sys.email_notifications_schedule_logicApp_identifier l
join
    db_sys.auditLog a
on
    (
        l.auditLog_ID = a.ID
    )
where
    (
        l.logicApp_ID = @logic_app_identifier
    )

update
    a
set
    a.eventUTCEnd = t.eventUTCEnd,
    a.eventDetail = 'Outcome: Failed'
from
    db_sys.auditLog a
join
    @t t
on
    (
        a.ID = t.auditLog_ID
    )
where
    a.eventUTCEnd is null
GO
