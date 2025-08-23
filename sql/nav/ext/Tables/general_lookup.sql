create table ext.general_lookup
    (
        id int identity(0,1),
        [Type] nvarchar(20) not null,
        [Code] nvarchar(20) not null,
        addTS datetime2(3) not null
    constraint PK__general_lookup primary key (id)
    )
go

alter table ext.general_lookup add constraint DF__general_lookup__addTS default getutcdate() for addTS
go

create unique index IX__224 on ext.general_lookup ([Type], [Code])
go