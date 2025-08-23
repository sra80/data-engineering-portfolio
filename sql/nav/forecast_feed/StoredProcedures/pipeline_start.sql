
create or alter procedure [forecast_feed].[pipeline_start]
    (
        @run_id uniqueidentifier,
        @df_name nvarchar(64),
        @pipe_name nvarchar(64)
    )

as

declare @eventName nvarchar(64) = left(concat(@df_name,':',@pipe_name),64), @auditLog_ID int

exec db_sys.sp_auditLog_start @eventType='Data Factory',@eventName=@eventName,@eventVersion='00',@placeHolder=@run_id,@placeHolder_session=@run_id

select @auditLog_ID = ID from db_sys.auditLog where eventDetail = convert(nvarchar(36),@run_id)

insert into db_sys.auditLog_dataFactory (auditLog_ID, run_ID) values (@auditLog_ID, @run_id)
GO
