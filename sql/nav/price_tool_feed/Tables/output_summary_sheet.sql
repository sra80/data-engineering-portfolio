create table price_tool_feed.output_summary_sheet
    (
        logic_app_id nvarchar(36) not null,
        is_current bit not null,
        file_path nvarchar(255) not null,
        row_count int not null,
        addTS datetime2(3)
    constraint PK__output_summary_sheet primary key (logic_app_id, file_path)
    )
go

alter table price_tool_feed.output_summary_sheet add constraint DF__output_summary_sheet__is_current default 1 for is_current
go

alter table price_tool_feed.output_summary_sheet add constraint DF__output_summary_sheet__addTS default sysdatetime() for addTS
go