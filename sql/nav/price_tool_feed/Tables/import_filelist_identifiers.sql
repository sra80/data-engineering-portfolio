create table price_tool_feed.import_filelist_identifiers
    (
        place_holder uniqueidentifier not null,
        filelist_id int not null,
    constraint PK__import_filelist_identifiers primary key (place_holder)
    )
go

alter table price_tool_feed.import_filelist_identifiers add constraint FK__import_filelist_identifiers__filelist_id foreign key (filelist_id) references price_tool_feed.import_filelist (id)
go

create unique index IX__A08 on price_tool_feed.import_filelist_identifiers (filelist_id)
go

grant alter on price_tool_feed.import_filelist_identifiers to [hs-bi-datawarehouse-price_tool_feed-import]
go