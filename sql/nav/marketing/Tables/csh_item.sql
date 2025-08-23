drop table if exists marketing.csh_item
go

create table marketing.csh_item
    (
        customer_id int not null,
        item_id int not null,
        _status int not null,
        scg_id int not null, --status change id
        date_start date not null,
        date_end date not null,
        addTS datetime2(0) not null,
        updateTS datetime2(0) not null
    constraint PK__csh_item primary key (customer_id, item_id, scg_id)
    )

alter table marketing.csh_item add constraint DF__csh_item__addTS default getutcdate() for addTS
go

alter table marketing.csh_item add constraint DF__csh_item__updateTS default getutcdate() for updateTS
go

alter table marketing.csh_item add constraint FK__csh_item__customer_id foreign key (customer_id) references hs_identity_link.Customer(ID)
go

alter table marketing.csh_item add constraint FK__csh_item__item_id foreign key (item_id) references ext.Item (ID)
go

create index IX__223 on marketing.csh_item (customer_id)
go

/*
create table marketing.csh_item
    (
        item_id int not null,
        _date date not null,
        _status int not null,
        _count int not null
    constraint PK__csh_item primary key (item_id, _date, _status)
    )
go
*/
/*
create table marketing.csh_item
    (
        customer_id int not null,
        item_id int not null,
        _date date not null,
        _status int not null,
        addTS datetime2(0) not null,
        updateTS datetime2(0) not null
    constraint PK__csh_item primary key (customer_id, item_id, _date)
    )
go

alter table marketing.csh_item add constraint DF__csh_item__addTS default getutcdate() for addTS
go

alter table marketing.csh_item add constraint DF__csh_item__updateTS default getutcdate() for updateTS
go

alter table marketing.csh_item add constraint FK__csh_item__customer_id foreign key (customer_id) references hs_identity_link.Customer(ID)
go

alter table marketing.csh_item add constraint FK__csh_item__item_id foreign key (item_id) references ext.Item (ID)
go

create index IX__223 on marketing.csh_item (customer_id)
go
*/
