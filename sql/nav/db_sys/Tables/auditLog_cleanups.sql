create table db_sys.auditLog_cleanups
    (
        auditLog_ID int not null,
        addTS datetime2(3) not null
    constraint PK__auditLog_cleanups primary key (auditLog_ID)
    )
go

alter table db_sys.auditLog_cleanups add constraint DF__auditLog_cleanups__addTS default getutcdate() for addTS
go