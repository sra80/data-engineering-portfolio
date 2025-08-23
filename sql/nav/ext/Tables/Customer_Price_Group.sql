create table ext.Customer_Price_Group
  (
    id int not null identity(0,1),
    company_id int not null,
    code nvarchar(10) not null,
    check_missing bit not null,
    is_ss bit not null,
    addTS datetime2(3) not null
  constraint PK__Customer_Price_Group primary key (id)
  )
go

create unique index IX__C6E on ext.Customer_Price_Group (company_id, code)
go

alter table ext.Customer_Price_Group add constraint DF__Customer_Price_Group__check_missing default 0 for check_missing
go

alter table ext.Customer_Price_Group add constraint DF__Customer_Price_Group__is_ss default 0 for is_ss
go

alter table ext.Customer_Price_Group add constraint DF__Customer_Price_Group__addTS default sysdatetime() for addTS
go
