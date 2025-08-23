



CREATE view [db_sys].[vw_auditLog_monitor]

as

with n as
	
	(

	select 
		 10000+((24-DATEPART(HOUR,eventUTCStart))*100)+(60-DATEPART(MINUTE,eventUTCStart)) [Task Status Order]
		,case when DATEDIFF(second,eventUTCStart,getutcdate())/convert(float,isnull(nullif((avg_runtime.total_rt/total_runs),0),1)) >= 1 then 0.99 else ROUND(DATEDIFF(second,eventUTCStart,getutcdate())/convert(float,isnull(nullif((avg_runtime.total_rt/total_runs),0),1)),2) end [Task Indicator]
		,'NAV_PROD_REPL' [Target Database]
		,eventUTCStart
		,convert(time,convert(datetime,datediff(second,eventUTCStart,getutcdate())*0.000011573883)) Runtime
		,al.eventType
		,al.eventName
		,case when eventUTCEnd is null then case al.eventType when 'Process Model' then 'Refresh Status: in progress' when 'Procedure' then 'Procedure Outcome: Running' else 'Status: Running' end else eventDetail end eventDetail
	from 
		db_sys.auditLog al
	join
		(
			select
				 eventType
				,eventName
				,SUM(DATEDIFF(second,eventUTCStart,eventUTCEnd)) total_rt
				,SUM(1) total_runs
			from
				db_sys.auditLog
			where
				(
					eventUTCEnd is not null
				and	eventUTCStart >= DATEADD(MONTH,-1,GETUTCDATE())
				and convert(time,eventUTCStart) >= convert(time,dateadd(MINUTE,-30,getutcdate()))
				and convert(time,eventUTCStart) <= convert(time,dateadd(MINUTE,30,getutcdate()))
				)
			group by
				 eventType
				,eventName

		) avg_runtime
	on
		(
			al.eventType = avg_runtime.eventType
		and	al.eventName = avg_runtime.eventName
		)
	where 
		eventUTCEnd is null

	union all

	select 20000+((24-DATEPART(HOUR,eventUTCStart))*100)+(60-DATEPART(MINUTE,eventUTCStart)), 1, 'NAV_PROD_REPL', eventUTCStart, convert(time,convert(datetime,datediff(second,eventUTCStart,eventUTCEnd)*0.000011573883)) Runtime, eventType, eventName, eventDetail from db_sys.auditLog where datediff(minute,eventUTCEnd,getutcdate()) <= 60

	union all

	select 
		 10000+((24-DATEPART(HOUR,eventUTCStart))*100)+(60-DATEPART(MINUTE,eventUTCStart)) [Task Status Order]
		,case when DATEDIFF(second,eventUTCStart,getutcdate())/convert(float,isnull(nullif((avg_runtime.total_rt/total_runs),0),1)) >= 1 then 0.99 else ROUND(DATEDIFF(second,eventUTCStart,getutcdate())/convert(float,isnull(nullif((avg_runtime.total_rt/total_runs),0),1)),2) end [Task Indicator]
		,'BI' [Target Database]
		,eventUTCStart
		,convert(time,convert(datetime,datediff(second,eventUTCStart,getutcdate())*0.000011573883)) Runtime
		,al.eventType
		,al.eventName
		,case when eventUTCEnd is null then case al.eventType when 'Process Model' then 'Refresh Status: in progress' when 'Procedure' then 'Procedure Outcome: Running' else 'Status: Running' end else eventDetail end eventDetail
	from 
		db_sys.auditLog_BI al
	join
		(
			select
				 eventType
				,eventName
				,SUM(DATEDIFF(second,eventUTCStart,eventUTCEnd)) total_rt
				,SUM(1) total_runs
			from
				db_sys.auditLog_BI
			where
				(
					eventUTCEnd is not null
				and	eventUTCStart >= DATEADD(MONTH,-1,GETUTCDATE())
				and convert(time,eventUTCStart) >= convert(time,dateadd(MINUTE,-30,getutcdate()))
				and convert(time,eventUTCStart) <= convert(time,dateadd(MINUTE,30,getutcdate()))
				)
			group by
				 eventType
				,eventName

		) avg_runtime
	on
		(
			al.eventType = avg_runtime.eventType
		and	al.eventName = avg_runtime.eventName
		)
	where 
		eventUTCEnd is null

	union all

	select 20000+((24-DATEPART(HOUR,eventUTCStart))*100)+(60-DATEPART(MINUTE,eventUTCStart)), 1, 'BI', eventUTCStart, convert(time,convert(datetime,datediff(second,eventUTCStart,eventUTCEnd)*0.000011573883)) Runtime, eventType, eventName, eventDetail from db_sys.auditLog_BI where datediff(minute,eventUTCEnd,getutcdate()) <= 60

	)

select 
	 [Task Status Order]
	,[Task Indicator]
	,[Target Database]
	,dateadd(minute,datediff(minute,eventUTCStart AT TIME ZONE isnull(tz.timezone,'GMT Standard Time'),eventUTCStart),eventUTCStart) [Task Start]
	,Runtime
	,case when eventType in ('Procedure','Logic App') then 'Run ' + eventType else eventType end [Task Type]
	,eventName [Task Name]
	,eventDetail [Task Status]
from
	n
outer apply
		(
			select timezone from db_sys.user_config where lower(SYSTEM_USER) = lower(username)
		) tz
GO
