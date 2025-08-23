
CREATE procedure forecast_feed.pipeline_end
    (
        @run_id uniqueidentifier
    )

as

exec db_sys.sp_auditLog_end @placeHolder=@run_id, @eventDetail='Pipeline Process Complete'
GO
