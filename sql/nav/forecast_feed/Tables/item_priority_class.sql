drop table if exists forecast_feed.item_priority_class
go

create table forecast_feed.item_priority_class
    (
        _period date not null,
        item_id int not null,
        new_quantity int not null,
        sub_quantity int not null,
        all_quantity int not null,
        sale_cost money not null,
        sale_net money not null,
        addTS datetime2(3) not null
    constraint PK__item_priority_class primary key (_period, item_id)
    )
go

alter table forecast_feed.item_priority_class add constraint DF__item_priority_class__addTS default getutcdate() for addTS
go

create index IX__856 on forecast_feed.item_priority_class (_period)
go

    