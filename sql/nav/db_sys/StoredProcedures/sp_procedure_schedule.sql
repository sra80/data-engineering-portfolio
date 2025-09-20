create or alter procedure [db_sys].[sp_procedure_schedule]
	(
		@pre_model bit = 0
	)

as

declare @job_execution_id uniqueidentifier, @eventVersion nvarchar(2), @eventType nvarchar(32) = 'Procedure', @job_name nvarchar(128), @place_holder_session uniqueidentifier

/* begin*/
update
    ps
set
    ps.process = 0,
    ps.process_active = 0
from
    db_sys.procedure_schedule ps
join
    jobs.job_executions je
on
    (
        ps.place_holder_session = je.job_execution_id
    and je.target_type = 'SqlDatabase'
    and je.target_database_name = db_name()
    )
left join
    db_sys.auditLog a
on
    (
        ps.place_holder = a.place_holder
    )
where
    (
        ps.process = 1
    and je.is_active = 0
    and a.place_holder is null
    )
/* end*/

if @pre_model = 1 begin set @job_name = 'procedure_schedule_pre_model' set @eventType += ' (Pre Model)' end else set @job_name = 'procedure_schedule'

select top 1 @job_execution_id = job_execution_id from jobs.job_executions where target_database_name = DB_NAME() and job_name = @job_name and is_active = 1

if @job_execution_id is null set @place_holder_session = newid() else set @place_holder_session = @job_execution_id

if @pre_model = 0 update s set process_active = 0 from db_sys.procedure_schedule s join db_sys.procedure_schedule_handler h on s.place_holder = h.place_holder join jobs.job_executions e on h.job_execution_id = e.job_execution_id where s.process_active = 1 and s.procedureName not in (select procedureName from db_sys.process_model_procedure_pairing) and e.is_active = 0 and e.target_database_name = DB_NAME()

if @pre_model = 1 update s set process_active = 0 from db_sys.procedure_schedule s join db_sys.procedure_schedule_handler h on s.place_holder = h.place_holder join jobs.job_executions e on h.job_execution_id = e.job_execution_id where s.process_active = 1 and s.procedureName in (select procedureName from db_sys.process_model_procedure_pairing) and e.is_active = 0 and e.target_database_name = DB_NAME()

--added 21/06/2021, added top level error handling to error log ***START***
insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorMessage)
select a.eventName, a.ID, e.last_message from db_sys.auditLog a join db_sys.procedure_schedule_handler h on try_convert(uniqueidentifier,a.eventDetail) = h.place_holder join jobs.job_executions e on h.job_execution_id = e.job_execution_id where e.is_active = 0 and e.target_database_name = DB_NAME() and e.lifecycle = 'Failed'
--added 21/06/2021, added top level error handling to error log ***END***

update a set eventUTCEnd = e.end_time, eventDetail = 'Job Execution Outcome: ' + e.lifecycle from db_sys.auditLog a join db_sys.procedure_schedule_handler h on a.place_holder = h.place_holder join jobs.job_executions e on h.job_execution_id = e.job_execution_id where e.is_active = 0 and e.target_database_name = DB_NAME() and a.eventUTCEnd is null

delete from db_sys.procedure_schedule_handler where job_execution_id in (select job_execution_id from jobs.job_executions where is_active = 0)

delete from 
    db_sys.procedure_schedule_queue
where 
    (
        dateadd(month,1,addTS) < getutcdate()
    )

--top level error handling added 11/06/2021 @ 2021-06-11T07:06:39.4360071+03:00***END

declare @exec nvarchar(max), @procedureName nvarchar(64), @place_holder uniqueidentifier, @auditLog_ID int, @eventDetail nvarchar(64), @error_message nvarchar(max), @error_count int, @version nvarchar(2), @eventUTCEnd datetime2(1)

--cleanup previous procedure runs begin***
declare [9ed666fe-51a3-44ba-9fde-927a7eccd87f] cursor for
select
    ps.place_holder, je.end_time
from
    db_sys.procedure_schedule ps
join
    jobs.job_executions je
on
    (
        ps.place_holder_session = je.job_execution_id
    )
where
    (
        ps.process = 1
    and je.is_active = 0
    and je.target_database_name = db_name()
    )

open [9ed666fe-51a3-44ba-9fde-927a7eccd87f]

fetch next from [9ed666fe-51a3-44ba-9fde-927a7eccd87f] into @place_holder, @eventUTCEnd

while @@fetch_status = 0

begin

exec db_sys.sp_auditLog_end @eventUTCEnd = @eventUTCEnd, @eventDetail = 'Procedure Outcome: Unknown', @placeHolder_ui = @place_holder

fetch next from [9ed666fe-51a3-44ba-9fde-927a7eccd87f] into @place_holder, @eventUTCEnd

end

close [9ed666fe-51a3-44ba-9fde-927a7eccd87f]
deallocate [9ed666fe-51a3-44ba-9fde-927a7eccd87f]
--cleanup previous procedure runs end***

--cleanup db_sys.procedure_schedule_queue  begin***
delete from
    db_sys.procedure_schedule_queue
where
    place_holder_session in
        (
            select
                x.place_holder_session
            from
                (
                select
                    place_holder_session,
                    sum(1) tasks,
                    sum(case when is_done = 1 then 1 else 0 end) is_done
                from 
                    db_sys.procedure_schedule_queue
                group by
                    place_holder_session
                ) x
            cross apply
                (
                    select top 1
                        addTS
                    from
                        db_sys.procedure_schedule_queue g
                    where
                        (
                            x.place_holder_session = g.place_holder_session
                        )
                ) w
            where
                (
                    x.is_done = x.tasks
                and dateadd(month,1,w.addTS) < getutcdate()
                )
        )
--cleanup db_sys.procedure_schedule_queue  end***

if @pre_model = 0

	begin

        update db_sys.procedure_schedule set 
            process = 1,
            place_holder_session = @place_holder_session,
            place_holder = newid()
        where
            schedule_disabled = 0
        and	process_active = 0
        and process = 0
        and db_sys.fn_set_process_flag(frequency_unit,frequency_value,last_processed,start_month,start_day,start_dow,start_hour,start_minute,end_month,end_day,end_dow,end_hour,end_minute,default) = 1
        and procedureName not in (select procedureName from db_sys.process_model_procedure_pairing)

        update 
            db_sys.procedure_schedule 
        set 
            process = 1,
            place_holder_session = @place_holder_session,
            place_holder = newid()
        where
            (
                run_on_next_session = 1
            and schedule_disabled = 0
            and	process_active = 0
            and process = 0
            )

    end

if @pre_model = 1

    begin

        insert into db_sys.procedure_schedule (procedureName)
        select
            procedureName
        from
            db_sys.process_model_partitions_procedure_pairing
        where
            procedureName not in (select procedureName from db_sys.procedure_schedule)

        update ps set
            ps.process = 1,
            ps.place_holder_session = @place_holder_session,
            ps.place_holder = newid()
        from
            db_sys.procedure_schedule ps
        join
            db_sys.process_model_procedure_pairing mp
        on
            (
                ps.procedureName = mp.procedureName
            )
        join
            db_sys.process_model k
        on
            (
                mp.model_name = k.model_name
            )
        outer apply
            (
                select top 1
                    1 process_flag
                from
                    db_sys.process_model_partitions pmp
                where
                    (
                        k.model_name = pmp.model_name
                    and db_sys.fn_set_process_flag
                            (
                                pmp.frequency_unit,
                                pmp.frequency_value,
                                ps.last_processed,
                                k.start_month,
                                k.start_day,
                                k.start_dow,
                                k.start_hour,
                                k.start_minute,
                                k.end_month,
                                k.end_day,
                                k.end_dow,
                                k.end_hour,
                                k.end_minute,
                                default
                            ) = 1
                    )
            ) xk
        where
            (
                k.disable_process = 0
            and k.process_active = 0
            and ps.schedule_disabled = 0
            and ps.process = 0
            and ps.process_active = 0
            and 
                (
                    db_sys.fn_set_process_flag
                        (
                            ps.frequency_unit,ps.frequency_value,
                            ps.last_processed,
                            ps.start_month,
                            ps.start_day,
                            ps.start_dow,
                            ps.start_hour,
                            ps.start_minute,
                            ps.end_month,
                            ps.end_day,
                            ps.end_dow,
                            ps.end_hour,
                            ps.end_minute,
                            default
                        ) = 1
                    or  xk.process_flag = 1
                )
            )

        update ps set
            ps.process = 1,
            ps.place_holder_session = @place_holder_session,
            ps.place_holder = newid()
        from
            db_sys.procedure_schedule ps
        join
            db_sys.process_model_partitions_procedure_pairing  mp
        on
            (
                ps.procedureName = mp.procedureName
            )
        join
            db_sys.process_model_partitions xw
        on
            (
                mp.model_name = xw.model_name
            and mp.table_name = xw.table_name
            and mp.partition_name = xw.partition_name
            )
        join
            db_sys.process_model g
        on
            (
                xw.model_name = g.model_name
            )
        where
            (
                ps.schedule_disabled = 0
            and ps.process = 0
            and ps.process_active = 0
            and xw.process = 1 --process model partitions process flag
            and xw.trigger_sp = 1 --only trigger paired procedures if on parition schedule, not when initiated by another procedure
            and g.disable_process = 0
            and g.process_active = 0
            )

        if (select isnull(sum(1),0) from db_sys.procedure_schedule where place_holder_session = @place_holder_session) > 0 --

            begin

                update ps set
                    ps.process = 1,
                    ps.place_holder_session = @place_holder_session,
                    ps.place_holder = newid()
                from
                    db_sys.procedure_schedule ps
                where
                    (
                        ps.procedureName = 'db_sys.recreate_missing_indexes'
                    and ps.schedule_disabled = 0
                    and ps.process = 0
                    and ps.process_active = 0
                    )

            end

    end

    insert into db_sys.procedure_schedule_queue (place_holder_session, procedureName, place_holder, job_execution_id)
    select
		place_holder_session,
        procedureName,
		place_holder,
        @job_execution_id
	from
		db_sys.procedure_schedule        
	where
		(
            place_holder_session = @place_holder_session
        and not exists
            (
                select
                    1
                from
                    db_sys.procedure_schedule_queue q
                where
                    (
                        procedure_schedule.place_holder_session = q.place_holder_session
                    and procedure_schedule.procedureName = q.procedureName
                    )
            )
        )

    while (select isnull(sum(1),0) from db_sys.procedure_schedule_queue where place_holder_session = @place_holder_session and is_done = 0) > 0

        begin

            select top 1
                @procedureName = procedureName,
                @place_holder = place_holder
            from
                db_sys.procedure_schedule_queue
            where
                (
                    place_holder_session = @place_holder_session
                and is_done = 0
                )
            order by
                case when procedureName = 'db_sys.recreate_missing_indexes' then 0 else 1 end

            update db_sys.procedure_schedule_queue set is_running = 1 where place_holder = @place_holder

            if not exists (select 1 from db_sys.procedure_schedule_handler where place_holder = @place_holder and job_execution_id = @job_execution_id) insert into db_sys.procedure_schedule_handler (place_holder,job_execution_id) values (@place_holder,@job_execution_id) --top level error handlder, see above

            select @eventVersion = db_sys.fn_procedure_version(@procedureName)

            exec db_sys.sp_auditLog_start @eventType=@eventType,@eventName=@procedureName,@eventVersion=@eventVersion,@placeHolder_ui=@place_holder,@placeHolder_session=@place_holder_session
                
            select @auditLog_ID = ID from db_sys.auditLog where place_holder = @place_holder

            -- if @job_execution_id is not null and @auditLog_ID is not null insert into db_sys.auditLog_sessions (ID,auditLog_ID) values (@job_execution_id,@auditLog_ID)

                begin try

                set @exec = @procedureName

                exec (@exec)

                set @eventDetail = 'Procedure Outcome: Success'

                update db_sys.procedure_schedule set error_count = 0 where procedureName = @procedureName

                insert into db_sys.procedure_schedule_queue (place_holder_session, procedureName, place_holder, job_execution_id)
                select
                    @place_holder_session,
                    child.procedureName,
                    newid(),
                    @job_execution_id
                from 
                    db_sys.procedure_schedule parent
                join
                    db_sys.procedure_schedule_pairing pair
                on
                    (
                        parent.procedureName = pair.procedureName_parent
                    )
                join
                    db_sys.procedure_schedule child
                on
                    (
                        pair.procedureName_child = child.procedureName
                    )
                where
                    (
                        parent.procedureName = @procedureName
                    and parent.place_holder_session = @place_holder_session
                    and child.schedule_disabled = 0
                    and child.process = 0
                    and child.process_active = 0
                    and (
                            child.place_holder_session != @place_holder_session
                        or  child.place_holder_session is null
                        )
                    and child.procedureName not in (select procedureName from db_sys.procedure_schedule_queue where place_holder_session = @place_holder_session)
                    )

                update 
                    child
                set 
                    child.process = 1,
                    child.place_holder_session = @place_holder_session,
                    child.place_holder = q.place_holder
                from 
                    db_sys.procedure_schedule parent
                join
                    db_sys.procedure_schedule_pairing pair
                on
                    (
                        parent.procedureName = pair.procedureName_parent
                    )
                join
                    db_sys.procedure_schedule child
                on
                    (
                        pair.procedureName_child = child.procedureName
                    )
                join
                    db_sys.procedure_schedule_queue q
                on
                    (
                        q.place_holder_session = @place_holder_session
                    and q.procedureName = child.procedureName
                    )
                where
                    (
                        parent.procedureName = @procedureName
                    and parent.place_holder_session = @place_holder_session
                    and child.schedule_disabled = 0
                    and child.process = 0
                    and child.process_active = 0
                    and child.place_holder_session != @place_holder_session
                    )

                end try

                begin catch

                update db_sys.procedure_schedule set error_count += 1 where procedureName = @procedureName

                set @error_message = error_message()

                select @error_count = error_count from db_sys.procedure_schedule where procedureName = @procedureName

                if @error_count >= 3 --automated disabling of a scheduled procedure reaching 3 or more errors in sequence, added 2021-09-10T15:00:23.9026181+03:00

                    begin 
                        update db_sys.procedure_schedule set schedule_disabled = 1 where procedureName = @procedureName 
                        set @error_message += 
                            '<p style="color:red">As the last ' + convert(nvarchar,@error_count) + ' execution attempts have failed, this procedure has been disabled.</p><p>Please correct the procedure and re-enable it in db_sys.procedure_schedule.'
                    end

                insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage) values (@procedureName, @auditLog_ID, error_line(), @error_message)

                set @eventDetail = 'Procedure Outcome: Failed'

                end catch

            exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@place_holder

            set @eventDetail = null

            set @error_count = null

            set @error_message = null

            update db_sys.procedure_schedule_queue set is_running = 0, is_done = 1 where place_holder = @place_holder

        end
GO
