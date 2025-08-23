create table stock.item_packaging_transactions
    (
        country_id int not null,
        key_posting_date date not null,
        key_location int not null,
        is_ic bit not null, --intercomany
        is_int bit not null, --international
        is_amazon bit not null,
        key_batch int not null,
        quantity int not null,
        addTS datetime2(3) not null
    constraint PK__item_packaging_transactions primary key (country_id, key_posting_date, key_location, is_ic, is_int, key_batch)
    )
go

alter table stock.item_packaging_transactions add constraint DF__item_packaging_transactions__is_ic default 0 for is_ic
go

alter table stock.item_packaging_transactions add constraint DF__item_packaging_transactions__is_int default 0 for is_int
go

alter table stock.item_packaging_transactions add constraint DF__item_packaging_transactions__addTS default getutcdate() for addTS
go

alter table stock.item_packaging_transactions add constraint DF__item_packaging_transactions__country_id default -1 for country_id
go

alter table stock.item_packaging_transactions add constraint DF__item_packaging_transactions__is_amazon default 0 for is_amazon
go

create index IX__563 on stock.item_packaging_transactions (key_posting_date)
go