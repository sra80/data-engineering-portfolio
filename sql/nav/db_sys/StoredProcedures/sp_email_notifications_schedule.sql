create or alter procedure [db_sys].[sp_email_notifications_schedule]
    (
        @place_holder_session uniqueidentifier = null,
        @logic_app_identifier nvarchar(36) = null
    )

as

declare 
	 @ID int
	,@email_trigger nvarchar(max) 
	,@email_to nvarchar(max) 
	,@email_cc nvarchar(max) 
	,@email_subject nvarchar(255) 
	,@email_bodyIntro nvarchar(max) 
	,@email_bodySource nvarchar(64) 
	,@email_bodyOutro nvarchar(max) 
	,@email_importance nvarchar(8) 
	,@result_param nvarchar(255)
	,@result bit
    ,@placeHolder uniqueidentifier --nvarchar(36)
    ,@eventName nvarchar(128)
    ,@eventDetail nvarchar(max)
    ,@success bit = 1
    ,@auditLog_ID int
	,@error_count int
    ,@error_message nvarchar(max)
	,@schedule_disabled bit
    ,@greeting bit

set @result_param = N'@result bit output'

update db_sys.email_notifications_schedule set 
    place_holder_session = @place_holder_session,
    is_queued = 1
where
		(
			schedule_disabled = 0
        and db_sys.fn_set_process_flag(frequency_unit,frequency_value,last_processed,start_month,start_day,start_dow,start_hour,start_minute,end_month,end_day,end_dow,end_hour,end_minute,default) = 1
        and is_processing = 0
		)

while (select isnull(sum(1),0) from db_sys.email_notifications_schedule where place_holder_session = @place_holder_session and is_queued = 1) > 0

begin --b1

    select top 1
        @ID = ID,
        @email_trigger = email_trigger,
        @email_to = email_to,
        @email_cc = email_cc,
        @email_subject = email_subject,
        @email_bodyIntro = email_bodyIntro,
        @email_bodySource = email_bodySource,
        @email_bodyOutro = email_bodyOutro,
        @email_importance = email_importance,
        @error_count = error_count,
        @schedule_disabled = schedule_disabled,
        @greeting = greeting
    from
        db_sys.email_notifications_schedule
    where
        (
            place_holder_session = @place_holder_session
        and is_queued = 1
        )

    -- begin transaction

        set @placeHolder = newid()

        update db_sys.email_notifications_schedule set is_processing = 1, place_holder = @placeHolder where ID = @ID

        set @eventName = concat('Subject: ',@email_subject,', Schedule ID: ',@ID)

        exec db_sys.sp_auditLog_start @eventType = 'Scheduled Alert',@eventName=@eventName,@eventVersion='00',@placeHolder_ui=@placeHolder,@placeHolder_session=@place_holder_session

        select @auditLog_ID = ID from db_sys.auditLog where place_holder = @placeHolder

        if @auditLog_ID is null set @auditLog_ID = -1 else if @logic_app_identifier is not null and (select isnull(sum(1),0) from db_sys.email_notifications_schedule_logicApp_identifier where auditLog_ID = @auditLog_ID) = 0 insert into db_sys.email_notifications_schedule_logicApp_identifier (logicApp_ID, auditLog_ID, ens_ID) values (@logic_app_identifier, @auditLog_ID, @ID)

        if @email_trigger is not null

            begin try --b2

                exec sp_executesql @email_trigger, @result_param, @result=@result output

                select @email_bodyIntro = email_bodyIntro, @email_subject = email_subject, @email_bodyOutro = email_bodyOutro from db_sys.email_notifications_schedule where ID = @ID --18/03/2022 @ 16:58 CET by SE -- for triggers that update the body of the e-mail

                set @error_count = 0

                update db_sys.email_notifications_schedule set reply_place_holder = @placeHolder where ID = @ID and reply_to_previous = 1 and reply_place_holder is null

                update db_sys.email_notifications_schedule set reply_place_holder = null where ID = @ID and reply_to_previous = 0 and reply_place_holder is not null

            end try --b2

            begin catch --b3

                select @result = 0, @success = 0, @error_count += 1

                set @error_message = ERROR_MESSAGE()

                insert into db_sys.email_notifications_schedule_errorLog (schedule_ID, auditLog_ID, error_message)
                values (@ID, @auditLog_ID, @error_message)

                set @email_bodyIntro = 'An error prevented the trigger associated with scheduled alert notication with subject ' + @email_subject + ' (email_notifications_schedule ID: ' + convert(nvarchar,@ID) + ') from completing successfully. The error message received was <i>' + @error_message + '</i>. The auditLog_ID is ' + convert(nvarchar,@auditLog_ID) + '.'

                if @error_count >= 3

                    begin --b4
                        
                        set @schedule_disabled = 1
                        
                        set @email_bodyIntro += 
                            '<p style="color:red">As the last ' + convert(nvarchar,@error_count) + ' attempts have failed, this scheduled alert has been disabled.</p><p>Once the issue has been identified and resolved, please re-enable it in db_sys.email_notifications_schedule.'
                    
                    end --b4

            end catch --b3

        if @email_trigger is null set @result = 1

        if @success = 1 and @result = 1 

            begin try --b5

                if @email_importance is null set @email_importance = 'Normal'

                exec db_sys.sp_email_notifications
                        @to=@email_to
                        ,@cc=@email_cc
                        ,@subject=@email_subject
                        ,@bodyIntro=@email_bodyIntro
                        ,@bodySource=@email_bodySource
                        ,@bodyOutro=@email_bodyOutro
                        ,@importance=@email_importance
                        ,@notifications_schedule_ID=@ID
                        ,@auditLog_ID=@auditLog_ID
                        ,@greeting=@greeting

                if (select isnull(sum(1),0) from db_sys.team_notification_setup where ens_ID = @ID) > 0

                exec db_sys.sp_email_notifications
                         @subject=@email_subject
                        ,@bodyIntro=@email_bodyIntro
                        ,@bodySource=@email_bodySource
                        ,@bodyOutro=@email_bodyOutro
                        ,@notifications_schedule_ID=@ID
                        ,@auditLog_ID=@auditLog_ID
                        ,@is_team_alert = 1

            end try --b5

            begin catch --b6

                select @success = 0, @error_count += 1

                set @error_message = ERROR_MESSAGE()

                insert into db_sys.email_notifications_schedule_errorLog (schedule_ID, auditLog_ID, error_message)
                values (@ID, @auditLog_ID, @error_message)

                set @email_bodyIntro = 'An error prevented the scheduled alert notication with subject ' + @email_subject + ' (email_notifications_schedule ID: ' + convert(nvarchar,@ID) + ') from completing successfully. The error message received was <i>' + @error_message + '</i>. The auditLog_ID is ' + convert(nvarchar,@auditLog_ID) + '.'

                if @error_count >= 3

                    begin --b7
                        
                        set @schedule_disabled = 1
                        
                        set @email_bodyIntro += 
                            '<p style="color:red">As the last ' + convert(nvarchar,@error_count) + ' attempts have failed, this scheduled alert has been disabled.</p><p>Once the issue has been identified and resolved, please re-enable it in db_sys.email_notifications_schedule.'
                    
                    end --b7

            end catch --b6

        if @success = 1 set @error_count = 0

        update db_sys.email_notifications_schedule set error_count = @error_count, schedule_disabled = @schedule_disabled where ID = @ID

        if @success = 1 

            begin --b8
            
            set @eventDetail = 'Outcome: Success, Alert Sent: ' 
            
                if exists (select 1 from db_sys.email_notifications where auditLog_ID = @auditLog_ID) or exists (select 1 from db_sys.team_notification_log where auditLog_ID = @auditLog_ID)
                    
                    set @eventDetail = @eventDetail + 'Yes'

                else

                    set @eventDetail = @eventDetail + 'No'

            end --b8

        else 

            begin --b9

            exec db_sys.sp_email_notifications @subject = 'Error Sending Scheduled Alert Notification', @bodyIntro = @email_bodyIntro, @notifications_schedule_ID = -1, @auditLog_ID = @auditLog_ID, @is_team_alert = 1, @tnc_id = 6
            
            set @eventDetail = 'Outcome: Failed'

            end --b9

        exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@placeHolder

        if @success = 1 update db_sys.email_notifications_schedule set last_processed = getutcdate() where ID = @ID

        update db_sys.email_notifications_schedule set is_processing = 0, is_queued = 0 where ID = @ID

        select	 @ID = null
                ,@email_trigger = null
                ,@email_to = null
                ,@email_cc = null
                ,@email_subject = null
                ,@email_bodyIntro = null
                ,@email_bodySource = null
                ,@email_bodyOutro = null
                ,@email_importance = null
                ,@result = null
                ,@success = 1
                ,@auditLog_ID = null
                ,@error_count = null
                ,@error_message = null
                ,@schedule_disabled = null
                ,@greeting = null

end --b1

-- commit transaction
GO