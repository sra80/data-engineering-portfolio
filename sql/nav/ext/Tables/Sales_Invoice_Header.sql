create table ext.Sales_Invoice_Header
    (
        id int not null identity(0,1),
        company_id int not null,
        No_ nvarchar(20) not null,
        customer_id int null
    )
go

alter table ext.Sales_Invoice_Header add constraint PK__Sales_Invoice_Header primary key (id)
go

alter table ext.Sales_Invoice_Header add constraint FK__Sales_Invoice_Header__customer_id foreign key (customer_id) references hs_identity_link.Customer (ID)
go

create unique index IX__476 on ext.Sales_Invoice_Header (company_id, No_)
go

create index IX__B63 on ext.Sales_Invoice_Header (customer_id)
go