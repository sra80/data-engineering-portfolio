create table price_tool_feed.import_pricemap
    (
        store_id int not null,
        pricetype_id int not null,
        price_group_id int not null,
        addTS datetime2(3) not null,
    constraint PK__import_pricemap primary key (store_id, pricetype_id, price_group_id)
    )
go

alter table price_tool_feed.import_pricemap add constraint FK__import_pricemap__store_id foreign key (store_id) references price_tool_feed.stores(store_id)
go

alter table price_tool_feed.import_pricemap add constraint FK__import_pricemap__pricetype_id foreign key (pricetype_id) references price_tool_feed.import_pricetype (id)
go

alter table price_tool_feed.import_pricemap add constraint FK__import_pricemap__price_group_id foreign key (price_group_id) references ext.Customer_Price_Group (id)
go

alter table price_tool_feed.import_pricemap add constraint DF__import_pricemap__addTS default sysdatetime() for addTS
go

/*
insert into price_tool_feed.import_pricemap (store_id, pricetype_id, price_group_id)
select distinct store_id, pricetype_id, case when store_id <= 3 then 39 else 122 end from price_tool_feed.import_pricelist

insert into price_tool_feed.import_pricemap (store_id, pricetype_id, price_group_id)
select store_id, pricetype_id, 120 from price_tool_feed.import_pricemap where store_id >= 4
*/