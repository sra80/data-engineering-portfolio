create or alter procedure [db_sys].[sp_auditLog_end]
    (
         @eventUTCStart nvarchar(32) = null
        ,@eventUTCEnd nvarchar(32) = null
        ,@last_processed_ts nvarchar(32) = null
        ,@eventType nvarchar(32) = null
        ,@eventName nvarchar(128) = null
        ,@eventVersion nvarchar(16) = null
        ,@eventDetail nvarchar(max) = null
        ,@placeHolder nvarchar(36) = null
        ,@placeHolder_session nvarchar(36) = null
        ,@placeHolder_ui uniqueidentifier = null
    )

as

set nocount on

/*
 Description:		Monitors scheduled tasks and triggers an email when tasks are overdue_from
 Project:			112
 Creator:			Shaun Edwards(SE)
 Copyright:			CompanyX Limited, 2021
MOD	DATE	INITS	COMMENTS
00  210325  SE      Created
01  220125  SE      Added logging in db_sys.auditLog_sessions
02  230710  SE      Add @eventType = 'Procedure (Pre Model)'
                    Set trigger_sp to 0 (false)
03  230713  SE      Add parameter @placeHolder_ui, interchangeable with @placeHolder
04  231122  SE      Set @eventUTCStart_dt to eventUTCStart of db_sys.auditLog where null
05  240306  SE      Set next_due
06  240927  SE      REM db_sys.auditLog_sessions, db_sys.auditLog now contains place_holder_session
*/

if @placeHolder is null set @placeHolder = convert(nvarchar(36),@placeHolder_ui)

if @placeHolder_ui is null set @placeHolder_ui = try_convert(uniqueidentifier,@placeHolder)

declare @eventUTCStart_dt datetime2, @eventUTCEnd_dt datetime2, @last_processed_ts_dt datetime2, @auditLog_ID int, @session_ID uniqueidentifier

set @eventUTCStart_dt = isnull(try_convert(datetime2,@eventUTCStart,127),(select eventUTCStart from db_sys.auditLog where place_holder = @placeHolder_ui /**/))

set @eventUTCEnd_dt = isnull(try_convert(datetime2,@eventUTCEnd,127),getutcdate())

set @last_processed_ts_dt = isnull(try_convert(datetime2,@last_processed_ts,127),@eventUTCStart_dt)

if @last_processed_ts_dt is null select @last_processed_ts_dt = eventUTCStart from db_sys.auditLog where place_holder = @placeHolder_ui

if @eventName is null select @eventName = eventName from db_sys.auditLog where place_holder = @placeHolder_ui 

if @eventType is null select @eventType = eventType from db_sys.auditLog where place_holder = @placeHolder_ui

select @auditLog_ID = ID from db_sys.auditLog where place_holder = @placeHolder_ui 

update db_sys.auditLog set eventUTCStart = isnull(@eventUTCStart_dt,eventUTCStart), eventUTCEnd = @eventUTCEnd_dt, eventType = @eventType, eventName = isnull(@eventName,eventName), eventVersion = isnull(@eventVersion,eventVersion), eventDetail = @eventDetail where place_holder = @placeHolder_ui and is_active = 1

if @eventType = 'Process Model'

    begin

    update db_sys.process_model set process_active = 0 where model_name = @eventName and place_holder = @placeHolder

    if try_convert(uniqueidentifier,@placeHolder_session) is not null 

        begin

        select @session_ID = job_execution_id from [db_sys].[pre_model_monitor] where place_holder = @placeHolder_session

        -- if @session_ID is not null and @auditLog_ID is not null and (select 1 from db_sys.auditLog_sessions where auditLog_ID = @auditLog_ID) is null insert into db_sys.auditLog_sessions (ID,auditLog_ID) values (@session_ID,@auditLog_ID)

        end

    end

if @eventType = 'Process Model' and @eventDetail = 'Refresh Status: succeeded'

    begin

        update 
            db_sys.process_model 
        set 
            overdue_from = null 
        where 
            (
                place_holder = @placeHolder_ui
            )

        update 
           h_pmp  
        set 
            h_pmp.process = 0,
            h_pmp.last_processed = @last_processed_ts_dt,
            h_pmp.next_due = db_sys.fn_set_process_next_due(h_pmp.frequency_unit,h_pmp.frequency_value,@last_processed_ts_dt,h_pm.start_month,h_pm.start_day,h_pm.start_dow,h_pm.start_hour,h_pm.start_minute,h_pm.end_month,h_pm.end_day,h_pm.end_dow,h_pm.end_hour,h_pm.end_minute,default,default),
            h_pmp.trigger_sp = 0
        from
            db_sys.process_model_partitions h_pmp
        join
            db_sys.process_model h_pm
        on
            (
                h_pmp.model_name = h_pm.model_name
            )
        where 
            (
                h_pmp.place_holder = @placeHolder_ui
            )

    end

if @eventType = 'Procedure'  or @eventType = 'Procedure (Pre Model)'

	begin

	if @eventDetail = 'Procedure Outcome: Success' 
    
        update 
            db_sys.procedure_schedule 
        set 
            process = 0,
            process_active = 0, 
            last_processed = @last_processed_ts_dt,
            run_on_next_session = 0,
            next_due = db_sys.fn_set_process_next_due(frequency_unit,frequency_value,@last_processed_ts_dt,start_month,start_day,start_dow,start_hour,start_minute,end_month,end_day,end_dow,end_hour,end_minute,default,default),
            overdue_from = null 
        where 
            (
                place_holder = @placeHolder_ui
            )

	else

	update 
        db_sys.procedure_schedule 
    set 
        process = 0,
        process_active = 0,
        last_processed = @last_processed_ts_dt,
        next_due = db_sys.fn_set_process_next_due(frequency_unit,frequency_value,@last_processed_ts_dt,start_month,start_day,start_dow,start_hour,start_minute,end_month,end_day,end_dow,end_hour,end_minute,default,default)
    where 
        (
            place_holder = @placeHolder_ui
        and schedule_disabled = 0
        )

end
GO

GRANT EXECUTE
    ON OBJECT::[db_sys].[sp_auditLog_end] TO [hs-bi-datawarehouse-forecast]
    AS [dbo];
GO
