create procedure [forecast_feed].[sp_stock_history_error]
    (
        @place_holder uniqueidentifier,
        @error_message nvarchar(max)
    )

as

set nocount on

declare @procedureName nvarchar(64) = 'forecast_feed.sp_stock_history', @auditLog_ID int

select @auditLog_ID = ID from db_sys.auditLog where eventDetail = convert(nvarchar(36),@place_holder)

insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage) values (@procedureName, @auditLog_ID, 0, @error_message)

exec db_sys.sp_auditLog_end @eventDetail='Procedure Outcome: Failed',@placeHolder_ui=@place_holder
GO
