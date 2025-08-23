create table ext.sales_item_doubles
    (
        sales_header_id int not null,
        order_date date not null,
        delivery_service_id int not null,
        item_id_1 int not null,
        item_id_2 int not null,
        units_ttl int not null,
        _count int not null,
        is_parcel bit not null,
        is_largeletter bit not null,
        addTS datetime2(3) not null
        constraint PK__sales_item_doubles primary key (sales_header_id, item_id_1, item_id_2)
    )
go

alter table ext.sales_item_doubles add constraint DF__sales_item_doubles__addTS default getutcdate() for addTS
go

alter table ext.sales_item_doubles add constraint DF__sales_item_doubles__is_parcel default 0 for is_parcel
go

alter table ext.sales_item_doubles add constraint DF__sales_item_doubles__is_largeletter default 0 for is_largeletter
go

create index IX__28D on ext.sales_item_doubles (sales_header_id)
go

CREATE NONCLUSTERED INDEX IX__09F
ON [ext].[sales_item_doubles] ([item_id_1],[item_id_2])
INCLUDE ([_count])
GO