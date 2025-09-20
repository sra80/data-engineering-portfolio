CREATE procedure [db_sys].[sp_run_procedure_email]
    (
         @procedureName nvarchar(64) 
        ,@notify_email nvarchar(max) = null
    )

as

set nocount on

declare @email_body nvarchar(max), @runtime int, @exec nvarchar(max)

set @exec = @procedureName


	
	begin try

	exec (@exec)


    set @email_body = 'The execution of procedure ' + @procedureName + ' has completed successfully' 

	end try

	begin catch

	
    set @email_body = 'The execution of procedure ' + @procedureName + ' failed to complete. Error message is <p><i>"' + error_message() + '"</i>'

	end catch



if @notify_email is not null exec db_sys.sp_email_notifications @to=@notify_email, @subject='SQL Procedure Execution Complete', @bodyIntro = @email_body, @greeting = 0
GO
