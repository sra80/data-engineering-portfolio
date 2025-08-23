create or alter procedure [db_sys].[sp_tasks_overdue]

as

set nocount on

/*
 Description:		Monitors scheduled tasks and triggers an email when tasks are overdue_from
 Project:			112
 Creator:			Shaun Edwards(SE)
 Copyright:			CompanyX Limited, 2025
MOD	DATE	INITS	COMMENTS
00  211022  SE      Created
01  211025  SE      Simplified and optimised procedure, simply checking every 5 minutes if a task is overdue_from, if so, trigger an email
02  211027  SE      Check if 'procedure_schedule' was actively running in job executions
03  211027  SE      Change how gap between triggers is measures, now based on column in db_sys.procedure_schedule called overdue_alert, one issued every 30 minutes
04  211028  SE      Fix: if a pre-model procedure, check job executions if job procedure_schedule_pre_model is actively running, also set trigger to run between 0700 and 2059
05  211028  SE      Overdue removed, this was counting up from 1 each time the trigger was run (every 5 minutes as of writing this), added overdue_from which is populated when a procedure is first identified as being overdue, this is more accurate, robust and flexible
06  211028  SE      Add logic to check for models overdue, it will not list partitions overdue, just the models
07  211101  SE      First alert to be issued after 1 hour & remove check on active jobs running
08  211101  SE      Add logic to check Cybersource recon, further changes made on 2/11: better logic to control frequency of notifications (1 hour between notifications), also include monitoring of stored procedures in BI
09  211129  SE      Add monitoring for replication
10  211129  SE      Add replication collision monitoring
11  211211  SE      Add logic to not include procedures overdue which are listed in db_sys.process_model_partitions_procedure_pairing
12  220201  SE      Add logic to check for jams in the system whereby a job has completed but the job is showing as incomplete in the auditLog which may affect the integrity of data models and reports
13  220210  SE      Add logic to send resolved notification for replications previously out of sync
14  220217  SE      Swap order of settings flags on db_sys.MSreplication_subscriptions_monitor, versionining flagged in script
15  221021  SE      Fix to email for resolved out of sync issues with replication
16  221128  SE      Add history to db_sys.auditLog
17  221129  SE      Reverse , set auditLog_ID in db_sys.email_notifications to -1
18  231020  SE      Send alerts to Business Intelligence channel in Business Intelligence Alerts in Teams
19  240325  SE      Fix: Replace function db_sys.fn_runTimeString (displaying incorrect delay - missing the hour and only showing the minute) with db_sys.fn_datediff_string
20  240514  SE      Add additional communication when a model is running late but is currrently processing
21  240927  SE      REM db_sys.auditLog_sessions, place_holder_session now on db_sys.auditLog
22  250115  SE      REM delay monitor on models, this is handled in db_sys.sp_process_model_delay_register and commmunicated in General Channel in Teams BI Alerts
*/

set nocount on

exec db_sys.sp_MSreplication_subscriptions_monitor

exec db_sys.sp_MSreplication_objects_collision

declare @hour int, @send_alert bit = 0, @send_good_news bit = 0

select @hour = datepart(hour,convert(datetime,switchoffset(getdate(),current_utc_offset))) from sys.time_zone_info where name = 'GMT Standard Time'

declare @email_body nvarchar(max) = '', @good_news_body nvarchar(max) = '', @place_holder uniqueidentifier, @tnl_ID int

declare @models table (model_name nvarchar(64), overdue_from datetime2(0), process_active bit, queued bit)
declare @procs table (source_database nvarchar(64), procedureName nvarchar(64), overdue_from datetime2(0))
declare @logicApps table (source_database nvarchar(64), logic_app nvarchar(64), overdue_from datetime2(0))
declare @jams table (ID int, job_execution_id uniqueidentifier) --

--input from BI Database
merge db_sys.tasks_overdue t
using
    (
        select 'BI' source_database, 'Procedure' task_type, procedureName task_name, db_sys.fn_set_process_flag(frequency_unit,frequency_value,last_processed,start_month,start_day,start_dow,start_hour,start_minute,end_month,end_day,end_dow,end_hour,end_minute,default) process_flag from db_sys.procedure_schedule_BI

        -- union all

        -- select 'BI', eventType, eventName, db_sys.fn_set_process_flag('hour',4,max(eventUTCStart),null,null,null,null,null,null,null,null,null,null,default) from db_sys.auditLog_BI where eventType = 'Logic App' and eventName = 'hs-bi-datawarehouse-la-cybersource' and eventUTCEnd is not null group by eventType, eventName

    ) s
on
    (
        t.source_database = s.source_database
    and t.task_type = s.task_type
    and t.task_name = s.task_name
    )
when not matched by target and s.process_flag = 1 then insert (source_database,task_type,task_name) values (s.source_database,s.task_type,s.task_name)
when matched and s.process_flag = 0 then delete;

--overdue models
update db_sys.process_model
    set overdue_from = 
        case when 
                @hour >= 6 
            and @hour <= 20 
            and disable_process = 0 
            and model_name in 
                (
                    select distinct 
                        m.model_name
                    from
                        db_sys.process_model m
                    join
                        db_sys.process_model_partitions p
                    on
                        m.model_name = p.model_name
                    cross apply
                        (
                            select
                                max(ts) ts
                            from
                                (
                                    values
                                        (p.last_processed),
                                        (p.last_offset_ts)
                                ) as x(ts)
                        ) ts
                    where
                        (
                            db_sys.fn_set_process_flag(p.frequency_unit,p.frequency_value,ts.ts,m.start_month,m.start_day,m.start_dow,m.start_hour,m.start_minute,m.end_month,m.end_day,m.end_dow,m.end_hour,m.end_minute,default) = 1
                        )
                ) 
        then isnull(overdue_from,getutcdate())
        else null 
        end

--overdue procedures
update db_sys.procedure_schedule
    set overdue_from = case when procedureName not in (select procedureName from db_sys.process_model_partitions_procedure_pairing union select procedureName from db_sys.process_model_procedure_pairing) /**/ and @hour >= 6 and @hour <= 20 and schedule_disabled = 0 and /*overdue_from is null and*/ db_sys.fn_set_process_flag(frequency_unit,frequency_value,last_processed,start_month,start_day,start_dow,start_hour,start_minute,end_month,end_day,end_dow,end_hour,end_minute,default) = 1 then isnull(overdue_from,getutcdate()) else null end

-- insert into @models (model_name, overdue_from, process_active, queued) select m.model_name, m.overdue_from, m.process_active, convert(bit,p.c) from db_sys.process_model m cross apply (select isnull(sum(1),0) c from db_sys.process_model_partitions p where m.model_name = p.model_name and p.process = 1 and m.process_active = 0) p where datediff(minute,m.overdue_from,getutcdate()) >= 60 and datediff(hour,m.overdue_from,getutcdate()) <= 24 and (m.overdue_alert is null or datediff(minute,m.overdue_alert,getutcdate()) >= 60) 

insert into @procs (source_database, procedureName, overdue_from) select db_name(), procedureName, overdue_from from db_sys.procedure_schedule where datediff(minute,overdue_from,getutcdate()) >= 60 and datediff(hour,overdue_from,getutcdate()) <= 24 and (overdue_alert is null or datediff(minute,overdue_alert,getutcdate()) >= 60)

insert into @procs (source_database, procedureName, overdue_from) select source_database, task_name, overdue_from from db_sys.tasks_overdue where task_type = 'Procedure' and datediff(minute,overdue_from,getutcdate()) >= 60 and datediff(hour,overdue_from,getutcdate()) <= 24 and (overdue_alert is null or datediff(minute,overdue_alert,getutcdate()) >= 60)

insert into @logicApps (source_database, logic_app, overdue_from) select source_database, task_name, overdue_from from db_sys.tasks_overdue where task_type = 'Logic App' and datediff(minute,overdue_from,getutcdate()) >= 60 and datediff(hour,overdue_from,getutcdate()) <= 24 and (overdue_alert is null or datediff(minute,overdue_alert,getutcdate()) >= 60)

insert into @jams (ID, job_execution_id) select a.ID, a.place_holder_session from db_sys.auditLog a join jobs.job_executions j on (j.job_execution_id = a.place_holder_session) where (j.is_active = 0 and j.target_type = 'SqlDatabase' and j.target_database_name = db_name() and a.eventUTCEnd is null and a.ID not in (select auditLog_ID from db_sys.auditLog_jams) and a.eventType in ('Procedure','Procedure (Pre Model)')) --

--replication
    if (select sum(1) from db_sys.MSreplication_subscriptions_monitor where issue_notification = 1) = 1 select top 1 @send_alert = 1, @email_body += 'The publication <b>' + publication + '</b> is running ' + db_sys.fn_datediff_string(transaction_timestamp_arrival,getutcdate(),5) + ' behind.<p>' from db_sys.MSreplication_subscriptions_monitor where issue_notification = 1

    if (select sum(1) from db_sys.MSreplication_subscriptions_monitor where issue_notification = 1) > 1 

        begin

            set @send_alert = 1
            set @email_body += 'The following publications are out of sync:<ul>'
            select @email_body += '<li>' + publication + ' (' + db_sys.fn_datediff_string(transaction_timestamp_arrival,getutcdate(),5) + ' behind)</li>' from db_sys.MSreplication_subscriptions_monitor where issue_notification = 1
            -- set @email_body += '</ul><p>'
            set @email_body += '</ul>'

        end

    --replication sync resolved
    if (select sum(1) from db_sys.MSreplication_subscriptions_monitor where resolved_notification = 1 and is_outofsync = 0) = 1 select top 1 @send_good_news = 1, @good_news_body += 'The publication <b>' + publication + '</b>, which was previously out of sync is now back on track.<p>' from db_sys.MSreplication_subscriptions_monitor where resolved_notification = 1 and is_outofsync = 0

    if (select sum(1) from db_sys.MSreplication_subscriptions_monitor where resolved_notification = 1 and is_outofsync = 0) > 1 

        begin

            set @send_good_news = 1
            set @good_news_body += 'The following publications which were previously out of sync are now back on track:<ul>'
            select @good_news_body += '<li>' + publication + '</li>' from db_sys.MSreplication_subscriptions_monitor where resolved_notification = 1 and is_outofsync = 0
            -- set @good_news_body += '</ul><p>'
            set @good_news_body += '</ul>'

        end


    --replication collision monitoring (article being published more than once)
    if (select sum(1) from db_sys.MSreplication_objects_collision where issue_notification = 1) = 1 select top 1 @send_alert = 1, @email_body += 'The article <b>' + article + '</b> has been published more than once in publications <b>' + publications + '</b>.<p>' from db_sys.MSreplication_objects_collision where issue_notification = 1

    if (select sum(1) from db_sys.MSreplication_objects_collision where issue_notification = 1) > 1 

        begin

            set @send_alert = 1
            set @email_body += 'The following articles have been published in multiple publications:<ul>'
            select @email_body += '<li>' + article + ' (in ' + publications + ')</li>' from db_sys.MSreplication_objects_collision where issue_notification = 1
            -- set @email_body += '</ul><p>'
            set @email_body += '</ul>'

        end

--data models
/*
    if (select sum(1) from @models) = 1 
    
        begin
        
            select top 1 @email_body += 'The model <b>' + model_name + '</b> is ' + db_sys.fn_datediff_string(overdue_from,getutcdate(),5) + ' overdue for processing' from @models
    
            if (select sum(1) from @models where process_active = 1) = 1 set @email_body += ', however it is currently processing'

            if (select sum(1) from @models where queued = 1) = 1 set @email_body += ', however it is currently queued for processing'

            -- set @email_body += '.<p>'
            set @email_body += '.'
        
        end

    if (select sum(1) from @models) > 1 

        begin

            set @email_body += 'The following models are overdue for processing:<ul>'
            select @email_body += '<li>' + model_name + ' - ' + db_sys.fn_datediff_string(overdue_from,getutcdate(),5) + ' overdue' + case when process_active = 1 then ' - currently processing' else case when queued = 1 then ' - queued' else '' end end + '</li>' from @models
            -- set @email_body += '</ul><p>'
            set @email_body += '</ul>'

        end
*/  
--stored procedures
    if (select sum(1) from @procs) = 1 select top 1 @email_body += 'The scheduled procedure <b>' + procedureName + '</b> in database ' + source_database + ' is ' + db_sys.fn_datediff_string(overdue_from,getutcdate(),5) + ' overdue for execution.' from @procs

    if (select sum(1) from @procs) > 1 

        begin

            set @email_body += 'The following procedures are overdue for execution:<ul>'
            select @email_body += '<li>' + source_database  + ': ' + procedureName + ' (' + db_sys.fn_datediff_string(overdue_from,getutcdate(),5) + ' overdue)</li>' from @procs
            -- set @email_body += '</ul><p>'
            set @email_body += '</ul>'

        end

--Logic Apps
    if (select sum(1) from @logicApps) = 1 select top 1 @email_body += 'The scheduled Logic App <b>' + logic_app + '</b> is ' + db_sys.fn_datediff_string(overdue_from,getutcdate(),5) + ' overdue for execution.' from @logicApps

    if (select sum(1) from @logicApps) > 1 

        begin

            set @email_body += 'The following Logic Apps are overdue:<ul>'
            select @email_body += '<li>' + logic_app + ' (' + db_sys.fn_datediff_string(overdue_from,getutcdate(),5) + ' overdue)</li>' from @logicApps
            -- set @email_body += '</ul><p>'
            set @email_body += '</ul>'

        end

--Jams in auditLog 
   if (select sum(1) from @jams) = 1 select top 1 @email_body += concat('The entry in the auditLog <b>',ID,'</b> is jammed, the execution of the job has completed, however the auditLog entry is incomplete, this could indicate an issue experienced with the Elastic Job Agent, such as the service unexpectedly restarting. The procedure db_sys.sp_auditLog_cleanups which runs every hour will clean this up, however it may be worth taking a look at the Elastic Job Agent (job_execution_id: ',job_execution_id,') for more details.') from @jams

    if (select sum(1) from @jams) > 1 

        begin

            set @email_body += 'The following entries in the auditLog are jammed, although the execution of the job has completed, the entries in the auditLog are incomplete, this might indicate an issue experienced with the Elastic Job Agent, such as the service unexpectedly restarting:<ul>'
            select @email_body += concat('<li>',ID,' (job_execution_id: ',job_execution_id,')</li>') from @jams
            set @email_body += '</ul>For further details, take a look at the Elastic Job Agent.'

        end

    if @hour >= 6 and @hour <= 20

        begin

            insert into db_sys.auditLog_jams (auditLog_ID) select ID from @jams

            -- if (select sum(1) from @procs) > 0 or (select sum(1) from @models) > 0 or (select sum(1) from @logicApps) > 0 or @send_alert = 1 set @email_body += '<p>Please check the system for any possible issues.'

            if ((select sum(1) from @procs) > 0 or (select sum(1) from @models) > 0 or (select sum(1) from @logicApps) > 0 or @send_alert = 1)

                begin --

                    set @place_holder = newid()
            
                    insert into db_sys.team_notification_log (auditLog_ID, ens_ID, message_subject, message_body, place_holder) values (-1, -1, 'System Issue', @email_body, @place_holder)

                    select @tnl_ID = ID from db_sys.team_notification_log where place_holder = @place_holder

                    insert into db_sys.team_notification_auditLog (tnl_ID, tnc_ID) values (@tnl_ID, 6)

                end

            if @send_good_news = 1

                begin --

                    set @place_holder = newid()
            
                    insert into db_sys.team_notification_log (auditLog_ID, ens_ID, message_subject, message_body, place_holder) values (-1, -1, 'System Update', @good_news_body, @place_holder)

                    select @tnl_ID = ID from db_sys.team_notification_log where place_holder = @place_holder

                    insert into db_sys.team_notification_auditLog (tnl_ID, tnc_ID) values (@tnl_ID, 6)
                
                end
            
            update db_sys.process_model set overdue_alert = getutcdate() where model_name in (select model_name from @models)
            
            update db_sys.procedure_schedule set overdue_alert = getutcdate() where procedureName in (select procedureName from @procs where source_database = db_name())

            update db_sys.tasks_overdue set overdue_alert = getutcdate() where exists (select 1 from @procs p where tasks_overdue.source_database = p.source_database and tasks_overdue.task_type = 'Procedure' and tasks_overdue.task_name = p.procedureName)

            update db_sys.tasks_overdue set overdue_alert = getutcdate() where exists (select 1 from @logicApps l where tasks_overdue.source_database = l.source_database and tasks_overdue.task_type = 'Logic App' and tasks_overdue.task_name = l.logic_app)
        
            update db_sys.MSreplication_subscriptions_monitor set resolved_notification = 0 where resolved_notification = 1 and is_outofsync = 0 -- order swap with below
            
            update db_sys.MSreplication_subscriptions_monitor set issue_notification = 0, notification_count += 1, last_notification = getutcdate() where issue_notification = 1 -- order swap with above

            update db_sys.MSreplication_objects_collision set first_notification = isnull(first_notification,getutcdate()), last_notification = getutcdate(), notification_count += 1, issue_notification = 0 where issue_notification = 1
        
        end
GO
