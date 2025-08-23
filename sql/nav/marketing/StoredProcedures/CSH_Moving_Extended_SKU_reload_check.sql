CREATE procedure [marketing].[CSH_Moving_Extended_SKU_reload_check]

as

if (select sum(1) from db_sys.auditLog where ID = 307145 and eventUTCEnd is not null) = 1 

begin

update db_sys.process_model set disable_process = 0 where model_name = 'Marketing_CRM' 

update db_sys.procedure_schedule set schedule_disabled = 1 where procedureName = 'marketing.CSH_Moving_Extended_SKU_reload_check'

end
GO
