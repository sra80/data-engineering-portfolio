create table price_tool_feed.export_pricelist  
    (
        external_id uniqueidentifier not null,
        item_id int not null,
        price_group_id int not null,
        price money not null,
        valid_from date not null,
        valid_to date not null,
        addTS datetime2(3) not null
    constraint PK__export_pricelist primary key (external_id, price_group_id)
    )
go

alter table price_tool_feed.export_pricelist add constraint DF__export_pricelist__addTS default sysdatetime() for addTS
go

alter table price_tool_feed.export_pricelist add constraint FK__export_pricelist__item_id foreign key (item_id) references ext.Item(ID)
go

alter table price_tool_feed.export_pricelist add constraint FK__export_pricelist__price_group_id foreign key (price_group_id) references ext.Customer_Price_Group(id)
go

create index IX__D39 on price_tool_feed.export_pricelist (item_id, price_group_id, price, valid_from, valid_to)
go