create procedure db_sys.sp_procedure_schedule_errorLog 
	(@ID int)


as

update db_sys.procedure_schedule_errorLog set messageSent = GETUTCDATE() where ID = @ID
GO

GRANT EXECUTE
    ON OBJECT::[db_sys].[sp_procedure_schedule_errorLog] TO [email_notifications]
    AS [dbo];
GO
