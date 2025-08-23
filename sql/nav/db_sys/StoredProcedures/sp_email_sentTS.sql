--select * from db_sys.vw_email_notifications

create procedure db_sys.sp_email_sentTS
	(
		@ID int
	)

as

update db_sys.email_notifications set email_sent = GETUTCDATE() where ID = @ID
GO

GRANT EXECUTE
    ON OBJECT::[db_sys].[sp_email_sentTS] TO [email_notifications]
    AS [dbo];
GO
