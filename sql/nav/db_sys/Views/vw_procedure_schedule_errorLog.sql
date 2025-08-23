

CREATE view [db_sys].[vw_procedure_schedule_errorLog]

as

select
	 ID,
     concat('Error Executing ',procedureName) alert_subject,
	'An error has occured while executing procedure <b>' + procedureName + '</b>, the error message is <i>"' + errorMessage + '"</i>' + errorMessage2 + '<p>The error was logged ' + case DATEDIFF(day,t.gg_ts,t.gg_time) when 0 then 'today' when 1 then 'yesterday' else ' on ' + format(t.gg_ts,'dd/MM/yyyy') end + ' at ' + format(t.gg_ts,'HH:mm') + '.<p>The auditLog ID is ' + convert(nvarchar,auditLog_ID) + ' and the error log ID is ' + convert(nvarchar,ID) + '.' alert_body
from
	(
		select
			 ID
			,auditLog_ID
			,procedureName
			,case when charindex('<',errorMessage) = 0 then errorMessage else substring(errorMessage,1,charindex('<',errorMessage)-1) end errorMessage
			,case when charindex('<',errorMessage) = 0 then '' else substring(errorMessage,charindex('<',errorMessage),len(errorMessage)-len(substring(errorMessage,1,charindex('<',errorMessage)-1))) end errorMessage2
			,dateAddedUTC
			,messageSent
		from
			db_sys.procedure_schedule_errorLog
        where
            report_error = 1
	) e
cross apply
	(
		select 
			 switchoffset(e.dateAddedUTC,current_utc_offset) gg_ts
			,switchoffset(GETUTCDATE(),current_utc_offset) gg_time
		from 
			sys.time_zone_info where name = 'GMT Standard Time'
	) t
where
	messageSent is null
GO
