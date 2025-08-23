create or alter procedure [db_sys].[sp_team_notification_log_posted]
    (
        @tnl_ID int,
        @tnc_ID int,
        @teams_message_id bigint = null,
        @place_holder_session uniqueidentifier = null
    )

as

update db_sys.team_notification_log set postTS = sysdatetime(), teams_message_id = @teams_message_id, place_holder_session = @place_holder_session where ID = @tnl_ID

update db_sys.team_notification_auditLog set postTS = sysdatetime() where tnl_ID = @tnl_ID and tnc_ID = @tnc_ID
GO
