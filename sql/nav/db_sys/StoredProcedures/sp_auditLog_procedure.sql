create or alter procedure [db_sys].[sp_auditLog_procedure]
    (
        @procedureName nvarchar(128),
        @notify_email nvarchar(max) = null,
		@report_error bit = 1,
        @report_error_every int = 1, --when @report_error is true, report every x occurrence, e.g. if set to 4, it's report the 4th, 8th, 12th, etc occurrences of the error occurring, this can be helpful for procedures that run frequently
        @parent_procedureName nvarchar(64) = null,
        @logicApp_ID nvarchar(36) = null,
        @place_holder_session uniqueidentifier = null,
        @check_disable_flag bit = 0,
        @next_process_offset_min int = 0
    )

as

set nocount on

declare @place_holder uniqueidentifier = newid(), @eventDetail nvarchar(64), @email_body nvarchar(max), @email_subject nvarchar(255), @runtime int, @auditLog_ID int, @exec nvarchar(max), @eventVersion nvarchar(2), @parent_auditLog_ID int, @error_count int

if datediff(minute,isnull((select last_processed from db_sys.procedure_schedule where procedureName = @procedureName),getutcdate()),getutcdate()) >= @next_process_offset_min

    begin

        exec db_sys.sp_auditLog_start @eventType = 'Procedure',@eventName=@procedureName,@eventVersion=@eventVersion,@placeHolder_ui=@place_holder,@logicApp_ID=@logicApp_ID,@placeHolder_session=@place_holder_session

        if @check_disable_flag = 1 and (select schedule_disabled from db_sys.procedure_schedule where procedureName = @procedureName) = 1

            begin

            exec db_sys.sp_auditLog_end @eventDetail='Procedure Outcome: Ignored (disabled)',@placeHolder_ui=@place_holder

            end

        else

            begin

                update db_sys.procedure_schedule set place_holder = @place_holder where procedureName = @procedureName

                set @eventVersion = db_sys.fn_procedure_version(@procedureName)

                if (select top 1 procedureName from db_sys.procedure_schedule where procedureName = @procedureName) is null insert into db_sys.procedure_schedule (procedureName, place_holder) values (@procedureName, @place_holder)

                set @exec = @procedureName

                select @auditLog_ID = ID from db_sys.auditLog where place_holder = @place_holder

                select @parent_auditLog_ID = ID from db_sys.auditLog where (eventType = 'Procedure' or eventType = 'Procedure (Pre Model)') and eventName = @parent_procedureName and try_convert(uniqueidentifier,eventDetail) is not null

                if @parent_auditLog_ID > 0 and @auditLog_ID > 0 and exists (select ID from db_sys.auditLog where ID = @parent_auditLog_ID)

                    begin

                        if @place_holder_session is null update db_sys.auditLog set place_holder_session = (select place_holder_session from db_sys.auditLog where ID = @parent_auditLog_ID) where ID = @auditLog_ID

                        if (select isnull(sum(1),0) from db_sys.auditLog_procedure_dependents where auditLog_ID = @auditLog_ID) = 0

                        insert into db_sys.auditLog_procedure_dependents (parent_auditLog_ID, auditLog_ID)
                        values (@parent_auditLog_ID, @auditLog_ID)

                    end
                    
                    begin try

                    exec (@exec)

                    set @eventDetail = 'Procedure Outcome: Success'
                    set @email_subject='SQL Procedure Execution Complete'
                    set @email_body = 'The execution of procedure ' + @procedureName + ' has completed successfully'

                    update db_sys.procedure_schedule set last_processed = getutcdate(), error_count = 0 where procedureName = @procedureName

                    end try

                    begin catch

                    select @error_count = error_count from db_sys.procedure_schedule where procedureName = @procedureName

                    set @error_count += 1

                    update db_sys.procedure_schedule set error_count = @error_count where procedureName = @procedureName

                    if @report_error = 1 and @error_count%@report_error_every > 0 set @report_error = 0

                    insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage, report_error) values (@procedureName, @auditLog_ID, error_line(), error_message(), @report_error)

                    set @eventDetail = 'Procedure Outcome: Failed'
                    set @email_subject='SQL Procedure Execution Failure'
                    set @email_body = 'The execution of procedure ' + @procedureName + ' failed to complete. Error message is <p><i>"' + error_message() + '"</i>'

                    end catch

                exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@place_holder

                select @runtime = datediff(second,eventUTCStart,eventUTCEnd) from db_sys.auditLog where ID = @auditLog_ID

                if isnull(@runtime,0) > 0 and @eventDetail = 'Procedure Outcome: Success'

                    begin

                        select @email_body += ' in ' + db_sys.fn_datediff_string(eventUTCStart,isnull(eventUTCEnd,getutcdate()),default) from db_sys.auditLog where ID = @auditLog_ID

                    end

                set @email_body += '.'

                if @notify_email is not null exec db_sys.sp_email_notifications @to=@notify_email, @subject=@email_subject, @bodyIntro = @email_body, @greeting = 0, @auditLog_ID=@auditLog_ID

            end

    end

GO