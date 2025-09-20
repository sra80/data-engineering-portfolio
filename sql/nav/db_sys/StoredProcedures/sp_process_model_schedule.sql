create or alter procedure [db_sys].[sp_process_model_schedule]

as

set nocount on

declare @current_ts datetime2 = getutcdate(), @last_entry int, @last_success datetime2(0), @last_success_place_holder uniqueidentifier, @current_entry int, @current_status int, @current_end_dt datetime2(0), @total_duration int, @process bit = 0, @send_to_0 bit = 0, @send_to_6 bit = 0, @message nvarchar(max), @subject nvarchar(255), @auto_nav_task_id uniqueidentifier = '90fe46af-ab16-4c0e-9daf-3f1194a0f9a5'

if db_sys.fn_set_process_flag('minute',15,(select top 1 last_update from db_sys.datetime_tracker where stored_procedure = 'db_sys.sp_process_model_schedule (offset)'),default,default,default,19,default,default,default,default,default,default,default) = 1

    begin /*ae1d*/

        update db_sys.datetime_tracker set last_update = @current_ts where stored_procedure = 'db_sys.sp_process_model_schedule (offset)'

        select @last_success = last_update from db_sys.datetime_tracker where stored_procedure = 'db_sys.sp_process_model_schedule (success)'

        select @last_entry = last_entry from db_sys.entry_no_tracker where stored_procedure = 'db_sys.sp_process_model_schedule' and table_name = '[dbo].[UK$AutoNAV Task Log Entry]'

        select top 1 @current_entry = [Entry No_], @current_status = [Status], @current_end_dt = [End Date_Time] from [dbo].[UK$AutoNAV Task Log Entry] where [AutoNAV Task ID] = @auto_nav_task_id and [Entry No_] > @last_entry order by [Entry No_] desc

        select
            @total_duration = isnull(sum(datediff(minute,[Start Date_Time],[End Date_Time])),0)
        from 
            [dbo].[UK$AutoNAV Task Log Entry] 
        where
            (
                [AutoNAV Task ID] = @auto_nav_task_id 
            and [Entry No_] > @last_entry 
            and [Status] = 0
            and [End Date_Time] > datefromparts(1753,1,1)
            )

        if @current_status = 0 and @current_end_dt > datefromparts(1753,1,1) and @total_duration >= 20

            begin /*4d1a*/

            update db_sys.entry_no_tracker set last_entry = @current_entry, last_update = @current_ts where stored_procedure = 'db_sys.sp_process_model_schedule' and table_name = '[dbo].[UK$AutoNAV Task Log Entry]'

            set @process = 1

            end /*4d1a*/

        if @current_status is not null 

            begin /*bcc9*/
        
                if @current_end_dt >= convert(date,@current_ts)

                    begin /*bc91*/

                        set @message = concat('The last ''',(select top 1 [Description] from [dbo].[UK$AutoNAV Task] where ID = @auto_nav_task_id),''' task from the AutoNAV queue ''',(select [Description] from [dbo].[UK$AutoNAV Task Queue] where Code = (select [AutoNAV Task Queue Code] from [dbo].[UK$AutoNAV Task] where ID = @auto_nav_task_id)),''' has completed with a status of ''',db_sys.fn_Lookup('AutoNAV Task Log Entry','Status',@current_status),'''.')

                        if @process = 1

                                begin /*f81f*/

                                    if datediff(day,@last_success,@current_ts) = 0

                                        begin /*f0b3*/

                                            select @last_success_place_holder = place_holder from db_sys.datetime_tracker where stored_procedure = 'db_sys.sp_process_model_schedule (success)'

                                            set @message += '<p>Since the task has completed successfully again, the partitions referenced above will be reprocessed.'

                                        end /*f0b3*/
                                    
                                    else

                                        begin /*5e5c*/

                                            set @message += '<p>As this task has completed successfully, the partitions of the following models which usually run at the start of each day (e.g. archive partitions) will run ahead of schedule:<ul><li>Finance_SalesInvoices</li><li>Logistics_OrderQueues</li><li>Marketing_SalesOrders</li></ul>This includes any procedures such partitions are dependent on. There may be some delays processing other models during this time.'

                                            set @last_success_place_holder = newid()

                                        end /*5e5c*/

                                    set @send_to_6 = 1

                                    update db_sys.datetime_tracker set last_update = @current_end_dt, place_holder = @last_success_place_holder where stored_procedure = 'db_sys.sp_process_model_schedule (success)'

                                end /*f81f*/

                        else if @process = 0 and datediff(day,@current_ts,db_sys.fn_set_process_next_due('minute',15,@current_ts,default,default,default,19,default,default,default,default,default,default,default,default)) > 0 and datediff(day,@last_success,@current_ts) > 0

                                begin /*46a5*/

                                if @total_duration < 20

                                    set @message += '<p>The last run of this task completed successfully, but with a runtime of under 20 minutes — suggesting minimal changes to the underlying data. As a result, certain overnight BI processes will be skipped until tomorrow evening. This will affect the following models:</p><ul><li>Finance_SalesInvoices - invoice figures will be lower than expected</li><li>Logistics_OrderQueues - dispatched not invoiced net revenue will be higher than expected</li></ul>'

                                else
                    
                                    begin /*9f8b*/
                                    
                                        set @message += '<p>This task has not completed successfully and this is the last check that will be made today. Since the last time the overnight processes ran, there have been additional runs of this task. Therefore, the overnight processes in the BI ecosystem will run now, allowing invoiced figures from those previous runs to be included in the reports.'

                                        set @process = 1

                                    end /*9f8b*/

                                    set @send_to_0 = 1
                                    
                                    set @send_to_6 = 1

                                end /*46a5*/

                    end /*bc91*/

                else if @current_end_dt = datefromparts(1753,1,1) and datediff(day,@current_ts,db_sys.fn_set_process_next_due('minute',15,@current_ts,default,default,default,19,default,default,default,default,default,default,default,default)) > 0 and datediff(day,@last_success,@current_ts) > 0

                    begin /*7d71*/

                        set @message = concat('The task ''',(select top 1 [Description] from [dbo].[UK$AutoNAV Task] where ID = @auto_nav_task_id),''' from the AutoNAV queue ''',(select [Description] from [dbo].[UK$AutoNAV Task Queue] where Code = (select [AutoNAV Task Queue Code] from [dbo].[UK$AutoNAV Task] where ID = @auto_nav_task_id)),''' is currently running and has a status of ''',db_sys.fn_Lookup('AutoNAV Task Log Entry','Status',@current_status),'''.')

                        if @total_duration < 20 
                        
                            set @message += '<p>As this task is still running and this is the last check that will be made today, certain overnight processes in the BI ecosystem will be skipped until tomorrow evening. This will impact the following models:<ul><li>Finance_SalesInvoices - invoice figures will be lower than expected</li><li>Logistics_OrderQueues - despatched not invoiced net revenue will be higher than expected</li></ul>'

                        else
                        
                            begin /*bcfb*/
                            
                                set @message += '<p>This task is still running and this is the last check that will be made today. Because there have been additional runs of this task since the last time the overnight processes were executed, the overnight processes in the BI ecosystem will be triggered now. This ensures that invoiced figures from those previous runs are included in the reports.'

                                set @process = 1

                            end /*bcfb*/

                        set @send_to_0 = 1

                        set @send_to_6 = 1

                    end /*7d71*/

            end /*bcc9*/

        else if @current_status is null and datediff(day,@current_ts,db_sys.fn_set_process_next_due('minute',15,@current_ts,default,default,default,19,default,default,default,default,default,default,default,default)) > 0 and datediff(day,@last_success,@current_ts) > 0

            begin /*af44*/

                set @message = concat('The task ''',(select top 1 [Description] from [dbo].[UK$AutoNAV Task] where ID = @auto_nav_task_id),''' from the AutoNAV queue ''',(select [Description] from [dbo].[UK$AutoNAV Task Queue] where Code = (select [AutoNAV Task Queue Code] from [dbo].[UK$AutoNAV Task] where ID = @auto_nav_task_id)),''' has not run')

                if datepart(dw,@current_ts) between 2 and 6
                
                    set @message += ' as expected this evening.'

                else

                    set @message = ' this evening.'

                if @total_duration < 20 

                    set @message += '<p>As this is the last check that will be made today, some overnight processes in the BI ecosystem will be skipped until tomorrow evening. This will impact the following models:<ul><li>Finance_SalesInvoices - invoice figures will be lower than expected</li><li>Logistics_OrderQueues - despatched not invoiced net revenue will be higher than expected</li></ul>'

                else
                        
                    begin /*7bbe*/
                    
                        set @message += '<p>Since this is the final check for today, and there have been additional runs since the last time the overnight processes were executed, the overnight processes in the BI ecosystem will run now. This will ensure that invoiced figures from those previous task runs are included in the reports.'

                        set @process = 1

                    end /*7bbe*/

                set @send_to_0 = 1

                set @send_to_6 = 1

            end /*af44*/

        if @send_to_0 = 1

                    begin /*4cdc*/

                        select @subject = concat('Status Update on NAV AutoTask [',[Description],']') from [dbo].[UK$AutoNAV Task] where ID = @auto_nav_task_id

                        exec db_sys.sp_email_notifications
                            @subject = @subject,
                            @bodyIntro = @message,
                            @is_team_alert = 1,
                            @tnc_id = 0

                    end /*4cdc*/

                if @send_to_6 = 1

                    begin /*9b7b*/

                        select @subject = concat('Status Update on NAV AutoTask [',[Description],']') from [dbo].[UK$AutoNAV Task] where ID = @auto_nav_task_id

                        if @last_success_place_holder is null set @last_success_place_holder = newid()

                        exec db_sys.sp_email_notifications
                            @subject = @subject,
                            @bodyIntro = @message,
                            @is_team_alert = 1,
                            @tnc_id = 6,
                            @place_holder = @last_success_place_holder

                    end /*9b7b*/

        update p set
            p.process = @process,
            p.trigger_sp = @process,
            p.last_offset_ts = dateadd(day,1,@current_ts)
        from
            db_sys.process_model m
        join
            db_sys.process_model_partitions p
        on
            (
                m.model_name = p.model_name
            )
        join
            db_sys.process_model_partitions_procedure_pairing pp
        on
            (
                p.model_name = pp.model_name
            and p.table_name = pp.table_name
            and p.partition_name = pp.partition_name
            )
        cross apply
            db_sys.fn_process_model_partitions_check(p.model_name,p.table_name,p.partition_name) c
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
            m.disable_process = 0
        and m.process_active = 0
        and p.process = 0
        and c.process = 0
        and pp.procedureName in ('finance.sp_SalesInvoices','ext.sp_sales @process_archive = 1')
        and db_sys.fn_set_process_flag(p.frequency_unit,p.frequency_value,p.last_processed,m.start_month,m.start_day,m.start_dow,m.start_hour,m.start_minute,m.end_month,m.end_day,m.end_dow,m.end_hour,m.end_minute,dateadd(day,1,@current_ts)) = 1
        and db_sys.fn_set_process_flag(p.frequency_unit,p.frequency_value,ts.ts,m.start_month,m.start_day,m.start_dow,m.start_hour,m.start_minute,m.end_month,m.end_day,m.end_dow,m.end_hour,m.end_minute,@current_ts) = 0

    end /*ae1d*/

update p set
    p.process = 1,
    p.trigger_sp = 1
from
    db_sys.process_model m
join
    db_sys.process_model_partitions p
on
    (
        m.model_name = p.model_name
    )
cross apply
    db_sys.fn_process_model_partitions_check(p.model_name,p.table_name,p.partition_name) c
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
    m.disable_process = 0
and m.process_active = 0
and p.process = 0
and c.process = 0
and db_sys.fn_set_process_flag(p.frequency_unit,p.frequency_value,ts.ts,m.start_month,m.start_day,m.start_dow,m.start_hour,m.start_minute,m.end_month,m.end_day,m.end_dow,m.end_hour,m.end_minute,@current_ts) = 1

update
    xpmp
set
    xpmp.process = 1,
    xpmp.trigger_sp = 1
from
    db_sys.process_model_partitions pmp
join
    db_sys.schedule_frequency_unit sfu
on
    (
        pmp.frequency_unit = sfu.frequency_unit
    )
cross apply
    (
        select
            xsfu.frequency_unit
        from
            db_sys.schedule_frequency_unit xsfu
        where
            sfu.id >= xsfu.id
    ) g
join
    db_sys.process_model_partitions xpmp
on
    (
        pmp.model_name = xpmp.model_name
    and g.frequency_unit = xpmp.frequency_unit
    and isnull(xpmp.last_offset_ts,@current_ts) <= @current_ts
    )
where
    (
        pmp.process = 1
    and xpmp.process = 0
    )

GO
