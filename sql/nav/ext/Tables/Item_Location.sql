create table ext.Item_Location
    (
        item_id int not null,
        location_id int not null,
        addTS datetime2(3) not null,
        sales_total decimal(38,20) not null,
        sales_single decimal(38,20) not null,
        sales_repeat decimal(38,20) not null,
        sales_update datetime2(3) null
    constraint PK__Item_Location_avg_sales primary key (item_id, location_id)
    )
go

alter table ext.Item_Location add constraint DF__Item_Location__addTS default sysdatetime() for addTS
go

alter table ext.Item_Location add constraint DF__Item_Location__sales_update default sysdatetime() for sales_update
go