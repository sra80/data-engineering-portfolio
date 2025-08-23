create table price_tool_feed.export_pricelist_vc
    (
        id int identity,
        logic_app_id nvarchar(36) not null,
        place_holder uniqueidentifier null,
        place_holder_session uniqueidentifier
        is_current bit not null,
        addTS datetime2(3) not null
    constraint PK__export_pricelist_vc primary key (id)
    )
go

alter table price_tool_feed.export_pricelist_vc add constraint DF__export_pricelist_vc__is_current default 0 for is_current
go

alter table price_tool_feed.export_pricelist_vc add constraint DF__export_pricelist_vc__addTS default sysdatetime() for addTS
go

create unique index IX__7E1 on price_tool_feed.export_pricelist_vc (is_current) where (is_current = 1)
go

create unique index IX__381 on price_tool_feed.export_pricelist_vc (logic_app_id)
go