create or alter procedure db_sys.sp_email_notifications_sessions
    (
        @place_holder_session uniqueidentifier,
        @logicApp_ID nvarchar(36) = null
    )

as

if @logicApp_ID is null

    update db_sys.email_notifications_sessions set is_active = 0, endTS = getutcdate() where place_holder_session = @place_holder_session

else

    insert into db_sys.email_notifications_sessions (place_holder_session, logicApp_ID)
    values (@place_holder_session, @logicApp_ID)