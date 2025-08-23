create or alter procedure db_sys.sp_pre_model_monitor_end
	(
		@place_holder nvarchar(36),
		@logic_app_identifier nvarchar(36) = null
	)

as

delete from [db_sys].pre_model_monitor where place_holder = @place_holder

update db_sys.auditLog_logicApp_identifier set is_active = 0 where ID = @logic_app_identifier
