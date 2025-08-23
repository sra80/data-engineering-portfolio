create table price_tool_feed.import_pricelist
    (
        id int not null,
        filelist_id int not null,
        pricetype_id int not null,
        item_id int not null,
        zone_id int not null,
        store_id int not null,
        price money not null,
        valid_from date not null,
        valid_to date null,
        external_id uniqueidentifier not null,
        external_id_original uniqueidentifier null, --the original line delivered to NAV
        is_processed bit not null,
        addTS datetime2(3) not null,
        processTS datetime2(3) null,
        is_in_HT bit not null, --sales price holding table
        is_in_SP bit not null, --sales price table
        is_in_next_post bit not null --true if to be included in next Teams post
    constraint PK__import_pricelist primary key (id)
    )
go

alter table price_tool_feed.import_pricelist add constraint FK__import_pricelist__filelist_id foreign key (filelist_id) references price_tool_feed.import_filelist (id)
go

alter table price_tool_feed.import_pricelist add constraint FK__import_pricelist__pricetype_id foreign key (pricetype_id) references price_tool_feed.import_pricetype (id)
go

alter table price_tool_feed.import_pricelist add constraint FK__import_pricelist__item_id foreign key (item_id) references ext.Item (ID)
go

alter table price_tool_feed.import_pricelist add constraint FK__import_pricelist__zone_id foreign key (zone_id) references price_tool_feed.zones (zone_id)
go

alter table price_tool_feed.import_pricelist add constraint FK__import_pricelist__store_id foreign key (store_id) references price_tool_feed.stores (store_id)
go

alter table price_tool_feed.import_pricelist add constraint DF__import_pricelist__external_id default (newid()) for external_id
go

alter table price_tool_feed.import_pricelist add constraint DF__import_pricelist__is_processed default (0) for is_processed
go

alter table price_tool_feed.import_pricelist add constraint DF__import_pricelist__addTS default (sysdatetime()) for addTS
go

alter table price_tool_feed.import_pricelist add constraint DF__import_pricelist__is_in_HT default (0) for is_in_HT
go

alter table price_tool_feed.import_pricelist add constraint DF__import_pricelist__is_in_SP default (0) for is_in_SP
go

alter table price_tool_feed.import_pricelist add constraint DF__import_pricelist__is_in_next_post default (0) for is_in_next_post
go

create index IX__1A0 on price_tool_feed.import_pricelist (filelist_id, pricetype_id, item_id, price, valid_from, valid_to, external_id)
go

create unique index IX__CC1 on price_tool_feed.import_pricelist (external_id)
go

create index IX__940 on price_tool_feed.import_pricelist (pricetype_id, store_id) where (is_processed = 0)
go

create index IX__C93 on price_tool_feed.import_pricelist (item_id, valid_from, valid_to) include (filelist_id, pricetype_id, store_id, price, external_id, is_processed, external_id_original)
go

create index IX__AD0 on price_tool_feed.import_pricelist (is_in_next_post)
go