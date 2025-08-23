create table ext.delivery_service
    (
        id int identity(0,1),
        company_id int not null,
        code nvarchar(20) not null,
        addTS datetime2(3) not null
    constraint PK__delivery_service primary key (id)
    )
go

alter table ext.delivery_service add constraint FK__delivery_service__company_id foreign key (company_id) references db_sys.Company(ID)
go

alter table ext.delivery_service add constraint DF__delivery_service__addTS default getutcdate() for addTS
go

create unique index IX__221 on ext.delivery_service (company_id, code)
go