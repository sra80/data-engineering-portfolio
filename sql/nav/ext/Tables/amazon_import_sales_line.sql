create table ext.amazon_import_sales_line
    (
        [id] int identity(0,1) not null,
        [sales_header_id] int not null,
        [sku] nvarchar(32) not null,
        [quantity_shipped] int not null,
        [item_price] money not null,
        [item_tax] money not null,
        [shipping_price] money not null,
        [shipping_tax] money not null,
        [item_promotion_discount] money not null,
        [ship_promotion_discount] money not null,
        [recon_auditLog_ID] int null,
        [recon_match_ratio] decimal(3,2) null
    constraint PK__amazon_import_sales_line primary key ([id])
    )
go

alter table ext.amazon_import_sales_line add constraint FK__amazon_import_sales_line__sales_header_id foreign key (sales_header_id) references ext.amazon_import_sales_header (id)
go

create unique index IX__3E7 on ext.amazon_import_sales_line ([sales_header_id], [sku])
go

create index IX__F40 on ext.amazon_import_sales_line (recon_auditLog_ID)
go

create index IX__79D on ext.amazon_import_sales_line (recon_match_ratio)
go

create index IX__73B on ext.amazon_import_sales_line ([sales_header_id])
go