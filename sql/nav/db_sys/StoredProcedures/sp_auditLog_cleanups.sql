create or alter procedure db_sys.sp_auditLog_cleanups

as

declare @auditLog_ID int, @place_holder uniqueidentifier, @eventUTCEnd datetime2(3), @eventDetail nvarchar(max)

--emails

declare [fe70c4a3-ba6b-4298-b1f4-b4d0f1e1eaa5] cursor for

    select
        a.ID,
        a.place_holder,
        isnull(a.lead_eventUTCStart,ens.endTS) eventUTCEnd
    from
        db_sys.email_notifications_sessions ens
    join
        (
            select
                ID,
                place_holder,
                place_holder_session,
                eventUTCEnd,
                dateadd(second,-1,lead(eventUTCStart) over (partition by place_holder_session order by eventUTCStart)) lead_eventUTCStart
            from
                db_sys.auditLog
        ) a
    on
        (
            ens.place_holder_session = a.place_holder_session
        )
    where
        (
            ens.is_active = 0
        and a.eventUTCEnd is null
        )

open [fe70c4a3-ba6b-4298-b1f4-b4d0f1e1eaa5]

fetch next from [fe70c4a3-ba6b-4298-b1f4-b4d0f1e1eaa5] into @auditLog_ID, @place_holder, @eventUTCEnd

while @@fetch_status = 0

    begin

        update db_sys.email_notifications_schedule set is_processing = 0, is_queued = 0 where place_holder = @place_holder

        exec db_sys.sp_auditLog_end @eventDetail='Outcome: Failed',@placeHolder_ui=@place_holder

        if (select auditLog_ID from db_sys.auditLog_cleanups where auditLog_ID = @auditLog_ID) is null

            begin

                insert into db_sys.auditLog_cleanups (auditLog_ID) values (@auditLog_ID)

            end

        fetch next from [fe70c4a3-ba6b-4298-b1f4-b4d0f1e1eaa5] into @auditLog_ID, @place_holder, @eventUTCEnd

    end

close [fe70c4a3-ba6b-4298-b1f4-b4d0f1e1eaa5]
deallocate [fe70c4a3-ba6b-4298-b1f4-b4d0f1e1eaa5]

--stored procedures

declare [a2c4c382-7bc5-4536-924b-ce45e744e6fd] cursor for

    select
        a.ID,
        a.place_holder,
        isnull(a.lead_eventUTCStart,jje.end_time) eventUTCEnd,
        concat('Job Execution Outcome: ',jje.lifecycle)
    from
        jobs.job_executions jje
    join
        (
            select
                ID,
                place_holder,
                place_holder_session,
                eventUTCEnd,
                dateadd(second,-1,lead(eventUTCStart) over (partition by place_holder_session order by eventUTCStart)) lead_eventUTCStart
            from
                db_sys.auditLog
            where
                (
                    eventType in ('Procedure','Procedure (Pre Model)')
                )
        ) a
    on
        (
            jje.job_execution_id = a.place_holder_session
        )
    where
        (
            jje.target_type = 'SqlDatabase'
        and jje.target_database_name = db_name()
        and jje.is_active = 0
        and a.eventUTCEnd is null
        )

open [a2c4c382-7bc5-4536-924b-ce45e744e6fd]

fetch next from [a2c4c382-7bc5-4536-924b-ce45e744e6fd] into @auditLog_ID, @place_holder, @eventUTCEnd, @eventDetail

while @@fetch_status = 0

    begin

        exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@place_holder

        if (select auditLog_ID from db_sys.auditLog_cleanups where auditLog_ID = @auditLog_ID) is null

            begin

                insert into db_sys.auditLog_cleanups (auditLog_ID) values (@auditLog_ID)

            end

        fetch next from [a2c4c382-7bc5-4536-924b-ce45e744e6fd] into @auditLog_ID, @place_holder, @eventUTCEnd, @eventDetail

    end

close [a2c4c382-7bc5-4536-924b-ce45e744e6fd]
deallocate [a2c4c382-7bc5-4536-924b-ce45e744e6fd]

--models

declare [7f88f982-a77b-4fb5-b98c-4120810a8ad5] cursor for

    select
        a.ID,
        a.place_holder,
        isnull(a.lead_eventUTCStart,ali.endTSUTC) eventUTCEnd
    from
        db_sys.auditLog_logicApp_identifier ali
    join
        (
            select
                ID,
                place_holder,
                place_holder_session,
                eventUTCEnd,
                dateadd(second,-1,lead(eventUTCStart) over (partition by place_holder_session order by eventUTCStart)) lead_eventUTCStart
            from
                db_sys.auditLog
            where
                (
                    eventType = 'Process Model'
                )
        ) a
    on
        (
            ali.sessionID = a.place_holder_session
        )
    where
        (
            ali.is_active = 0
        and a.eventUTCEnd is null
        )

open [7f88f982-a77b-4fb5-b98c-4120810a8ad5]

fetch next from [7f88f982-a77b-4fb5-b98c-4120810a8ad5] into @auditLog_ID, @place_holder, @eventUTCEnd

while @@fetch_status = 0

    begin

        exec db_sys.sp_auditLog_end @eventDetail='Refresh Status: unknown (db_sys.sp_auditLog_cleanups)',@placeHolder_ui=@place_holder

        if (select auditLog_ID from db_sys.auditLog_cleanups where auditLog_ID = @auditLog_ID) is null

            begin

                insert into db_sys.auditLog_cleanups (auditLog_ID) values (@auditLog_ID)

            end

        fetch next from [7f88f982-a77b-4fb5-b98c-4120810a8ad5] into @auditLog_ID, @place_holder, @eventUTCEnd

    end

close [7f88f982-a77b-4fb5-b98c-4120810a8ad5]
deallocate [7f88f982-a77b-4fb5-b98c-4120810a8ad5]