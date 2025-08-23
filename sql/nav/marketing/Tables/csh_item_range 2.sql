drop table if exists marketing.csh_item_range
go

create table marketing.csh_item_range
    (
        customer_id int not null,
        range_id int not null,
        _status int not null,
        scg_id int not null, --status change id
        date_start date not null,
        date_end date not null,
        addTS datetime2(0) not null,
        updateTS datetime2(0) null
    constraint PK__csh_item_range primary key (customer_id, range_id, scg_id)
    )

alter table marketing.csh_item_range add constraint DF__csh_item_range__addTS default getutcdate() for addTS
go

alter table marketing.csh_item_range add constraint FK__csh_item_range__customer_id foreign key (customer_id) references hs_identity_link.Customer(ID)
go

alter table marketing.csh_item_range add constraint FK__csh_item_range__range_id foreign key (range_id) references ext.Range (ID)
go

create index IX__8EA on marketing.csh_item_range (customer_id)
go