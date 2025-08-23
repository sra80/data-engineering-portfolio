create table price_tool_feed.import_pricetype
    (
        id int not null identity(1,1),
        price_type nvarchar(64) not null,
        is_rrp bit not null,
        addTS datetime2(3) not null
    )
go

alter table price_tool_feed.import_pricetype add constraint PK__import_pricetype primary key (id)
go

alter table price_tool_feed.import_pricetype add constraint DF__import_pricetype__is_rrp default (0) for is_rrp
go

alter table price_tool_feed.import_pricetype add constraint DF__import_pricetype__addTS default (sysdatetime()) for addTS
go

create unique index IX__82B on price_tool_feed.import_pricetype (price_type)
go

create unique index IX__59B on price_tool_feed.import_pricetype (is_rrp) where (is_rrp = 1)
go