create table ext.amazon_import_sales_header
    (
        [id] int identity(0,1) not null,
        [filelist_id] int not null,
        [amazon_order_id_p1] int not null,
        [amazon_order_id_p2] int not null,
        [amazon_order_id_p3] int not null,
        [merchant_order_id]  nvarchar(32) null,
        [shipment_id] nvarchar(32) null,
        [purchase_date] datetime2(0) not null,
        [payments_date] datetime2(0) not null,
        [shipment_date] datetime2(0) not null,
        [reporting_date] datetime2(0) not null,
        [currency] nvarchar(32) not null,
        [ship_service_level] nvarchar(32) not null,
        [ship_city] nvarchar(32) not null,
        [ship_state] nvarchar(32) not null,
        [ship_postal_code] nvarchar(32),
        [ship_country] nvarchar(32) not null,
        [carrier] nvarchar(32) not null,
        [estimated_arrival_date] date not null,
        [fulfillment_center_id] nvarchar(32) not null,
        [fulfillment_channel] nvarchar(32) not null,
        [sales_channel] nvarchar(255) not null
    constraint PK__amazon_import_sales_header primary key (id)
    )
go

alter table ext.amazon_import_sales_header add constraint FK__amazon_import_sales_header__filelist_id foreign key (filelist_id) references ext.amazon_import_filelist (id)
go

create unique index IX__C03 on ext.amazon_import_sales_header ([amazon_order_id_p1], [amazon_order_id_p2], [amazon_order_id_p3])
go

create index IX__16A on ext.amazon_import_sales_header ([filelist_id])
go

create unique index IX__1DA on ext.amazon_import_sales_header (merchant_order_id) where (merchant_order_id is not null)
go