create table price_tool_feed.export_pricelist_errorlog
    (
        external_id uniqueidentifier not null,
        issue_raised nvarchar(max) not null,
        addTS datetime2(3) not null
    constraint PK__export_pricelist_errorlog primary key (external_id)
    )
go

alter table price_tool_feed.export_pricelist_errorlog add constraint DF__export_pricelist_errorlog__addTS default getutcdate() for addTS
go