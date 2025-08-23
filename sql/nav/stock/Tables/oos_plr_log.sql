create table stock.oos_plr_log
    (
        item_id int not null,
        row_version int not null,
        rv_sub int not null,
        ts_start datetime2(3) not null,
        ts_end datetime2(3) null
    constraint PK__oos_plr_log primary key (item_id, row_version, rv_sub)
    )
go

alter table stock.oos_plr_log add constraint DF__oos_plr_log__rv_sub default 0 for rv_sub
go

alter table stock.oos_plr_log add constraint DF__oos_plr_log__ts_start default getutcdate() for ts_start
go

create index IX__77B on stock.oos_plr_log (item_id, row_version)
go