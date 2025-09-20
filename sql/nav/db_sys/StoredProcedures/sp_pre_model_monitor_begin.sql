CREATE procedure [db_sys].[sp_pre_model_monitor_begin] 
	(
		@place_holder nvarchar(36),
        @logic_app_identifier nvarchar(36) = null
	)
as 

set nocount on

declare @je uniqueidentifier

EXEC db_sys.sp_start_job_remote @job_name = N'procedure_schedule_pre_model', @job_execution_id = @je OUTPUT

insert into [db_sys].[pre_model_monitor] ([place_holder],[job_execution_id],[active]) values (@place_holder,@je,1)

if @logic_app_identifier is not null and @logic_app_identifier not in (select ID from db_sys.auditLog_logicApp_identifier) insert into db_sys.auditLog_logicApp_identifier (ID, sessionID) values (@logic_app_identifier, @je)
GO
