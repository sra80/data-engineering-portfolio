



CREATE VIEW [ext].[SS_Payment_Attempts_timestamp]

as

select dateadd(hour,datediff(hour,[last_processed] at time zone 'GMT Standard Time',[last_processed]),[last_processed]) [Last Update] from [db_sys].[procedure_schedule] where [procedureName] = 'ext.sp_SS_Payment_Attempts'
GO

GRANT SELECT
    ON OBJECT::[ext].[SS_Payment_Attempts_timestamp] TO [All CompanyX Staff]
    AS [dbo];
GO
