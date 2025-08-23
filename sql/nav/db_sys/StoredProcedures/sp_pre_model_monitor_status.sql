
CREATE procedure [db_sys].[sp_pre_model_monitor_status]
	(
		@place_holder nvarchar(36)
	)

as

set nocount on

declare @active bit = 0, @je uniqueidentifier

select @je = [job_execution_id] from [db_sys].pre_model_monitor where place_holder = @place_holder

select @active = is_active from jobs.job_executions where [job_execution_id] = @je and target_database_name = DB_NAME()

update [db_sys].[pre_model_monitor] set active = @active where place_holder = @place_holder
GO
