
create or alter procedure [forecast_feed].[sp_stage_forecast_truncate]
    (
        @run_id uniqueidentifier = null
    )

as 

set nocount on

declare @procedureName nvarchar(64) = 'forecast_feed.sp_stage_forecast_truncate'

declare @place_holder uniqueidentifier = newid(), @auditLog_ID int, @parent_auditLog_ID int, @eventDetail nvarchar(64)

exec db_sys.sp_auditLog_start @eventType = 'Procedure',@eventName=@procedureName,@eventVersion='00',@placeHolder_ui=@place_holder,@placeHolder_session=@run_id

select @auditLog_ID = ID from db_sys.auditLog where eventDetail = convert(nvarchar(36),@place_holder)

select @parent_auditLog_ID = auditLog_ID from db_sys.auditLog_dataFactory where run_ID = @run_id

        if @auditLog_ID > 0 and @parent_auditLog_ID > 0 and (select isnull(sum(1),0) from db_sys.auditLog_procedure_dependents where auditLog_ID = @auditLog_ID) = 0

        insert into db_sys.auditLog_procedure_dependents (parent_auditLog_ID, auditLog_ID)
        values (@parent_auditLog_ID, @auditLog_ID)

begin try

    truncate table forecast_feed.stage_forecast

    set @eventDetail = 'Procedure Outcome: Success'

end try

begin catch

    set @eventDetail = 'Procedure Outcome: Failed'

    insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage) values (@procedureName, @auditLog_ID, error_line(), error_message())

end catch

exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@place_holder
GO
