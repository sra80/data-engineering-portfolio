create table price_tool_feed.import_errors
    (
        filelist_id int not null,
        error nvarchar(max) not null,
        addTS datetime2(3) not null,
        postTS datetime2(3) null
    constraint PK__import_errors primary key (filelist_id)
    )
go

alter table price_tool_feed.import_errors add constraint FK__import_errors__filelist_id foreign key (filelist_id) references price_tool_feed.import_filelist (id)
go

alter table price_tool_feed.import_errors add constraint DF__import_errors__addTS default (sysdatetime()) for addTS
go
