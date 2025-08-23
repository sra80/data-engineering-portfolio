


CREATE view [ext].[iOSS_timestamp]


as	

select dateadd(hour,datediff(hour,[last_processed] at time zone 'GMT Standard Time',[last_processed]),[last_processed]) [last_processed] from [db_sys].[procedure_schedule] where [procedureName] = 'ext.sp_iOSS'
GO

GRANT SELECT
    ON OBJECT::[ext].[iOSS_timestamp] TO [Finance_Users]
    AS [dbo];
GO
