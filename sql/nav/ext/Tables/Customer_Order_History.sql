create table ext.Customer_Order_History
    (
        order_ref nvarchar(20) not null,
        order_date date not null,
        cus nvarchar(20) not null,
        integration_code nvarchar(20) null,
        channel_code nvarchar(10) not null,
        addTS datetime2(0) not null
    constraint PK__Customer_Order_History primary key (order_ref)
    )

create index IX__1BD on ext.Customer_Order_History (cus)
go

alter table ext.Customer_Order_History add constraint DF__Customer_Order_History__addTS default getutcdate() for addTS
go