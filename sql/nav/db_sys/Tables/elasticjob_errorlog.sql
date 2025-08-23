create table db_sys.elasticjob_errorlog
    (
        job_execution_id uniqueidentifier not null,
        addTS datetime2(3) not null
    constraint PK__elasticjob_errorlog primary key (job_execution_id)
    )
go

alter table db_sys.elasticjob_errorlog add constraint DF__elasticjob_errorlog__addTS default getutcdate() for addTS
go