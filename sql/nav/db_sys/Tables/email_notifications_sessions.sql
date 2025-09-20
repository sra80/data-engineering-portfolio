create table db_sys.email_notifications_sessions
    (
        [place_holder_session] uniqueidentifier not null,
        [logicApp_ID] nvarchar(36) not null,
        [is_active] bit not null,
        [startTS] datetime2(3) not null,
        [endTS] datetime2(3) null
    constraint PK__email_notifications_sessions primary key (place_holder_session)
    )
go

create unique index IX__5A0 on db_sys.email_notifications_sessions (logicApp_ID)
go

alter table db_sys.email_notifications_sessions add constraint DF__email_notifications_sessions__is_active default 1 for is_active
go

alter table db_sys.email_notifications_sessions add constraint DF__email_notifications_sessions__startTS default getutcdate() for startTS
go