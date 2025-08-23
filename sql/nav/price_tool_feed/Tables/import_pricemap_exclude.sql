create table price_tool_feed.import_pricemap_exclude
 (
    store_id int not null,
    pricetype_id int not null,
    addTS datetime2(3) not null,
    constraint PK__import_pricemap_exclude primary key (store_id, pricetype_id)
 )

alter table price_tool_feed.import_pricemap_exclude add constraint FK__import_pricemap_exclude__store_id foreign key (store_id) references price_tool_feed.stores(store_id)
go

alter table price_tool_feed.import_pricemap_exclude add constraint FK__import_pricemap_exclude__pricetype_id foreign key (pricetype_id) references price_tool_feed.import_pricetype (id)
go

alter table price_tool_feed.import_pricemap_exclude add constraint DF__import_pricemap_exclude__addTS default sysdatetime() for addTS
go

insert into price_tool_feed.import_pricemap_exclude (store_id, pricetype_id)
select
    s.store_id,
    t.pricetype_id
from
    (select 4 store_id union all select 5) s
cross apply
    (select 1 pricetype_id union all select 2) t
go