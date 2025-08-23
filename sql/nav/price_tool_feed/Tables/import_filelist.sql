create table price_tool_feed.import_filelist
    (
        id int not null identity(1,1),
        blob_id nvarchar(128) not null,
        blob_name nvarchar(64) not null,
        blob_modified datetime2(3) not null,
        is_invalid bit not null,
        addTS datetime2(3) not null,
        auditLog_ID int null,
        place_holder uniqueidentifier null,
        logic_app_id nvarchar(36) null,
        is_done bit not null,
        is_test bit not null, --if true, the file is excluded from checking in NAV
        original_entry_count int null
    )
go

alter table price_tool_feed.import_filelist add constraint PK__import_filelist primary key (id)
go

alter table price_tool_feed.import_filelist add constraint DF__import_filelist__addTS default sysdatetime() for addTS
go

alter table price_tool_feed.import_filelist add constraint DF__import_filelist__is_invalid default 0 for is_invalid
go

alter table price_tool_feed.import_filelist add constraint DF__import_filelist__is_done default 0 for is_done
go

alter table price_tool_feed.import_filelist add constraint DF__import_filelist__is_test default 0 for is_test
go