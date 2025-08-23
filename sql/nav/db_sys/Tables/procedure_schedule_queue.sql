create table db_sys.procedure_schedule_queue
    (
        place_holder_session uniqueidentifier not null,
        procedureName nvarchar(128) not null,
        place_holder uniqueidentifier not null,
        is_running bit not null,
        is_done bit not null,
        job_execution_id uniqueidentifier null,
        addTS datetime2(3) not null
    )
go

alter table db_sys.procedure_schedule_queue add constraint PK__procedure_schedule_queue primary key (place_holder_session, procedureName)
go

alter table db_sys.procedure_schedule_queue add constraint DF__procedure_schedule_queue__is_done default 0 for is_done
go

alter table db_sys.procedure_schedule_queue add constraint DF__procedure_schedule_queue__is_running default 0 for is_running
go

alter table db_sys.procedure_schedule_queue add constraint DF__procedure_schedule_queue__addTS default getutcdate() for addTS
go

create unique index IX__CC8 on db_sys.procedure_schedule_queue (place_holder)
go