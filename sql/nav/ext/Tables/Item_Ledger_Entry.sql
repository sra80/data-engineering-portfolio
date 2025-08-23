create table ext.Item_Ledger_Entry
    (
        company_id int not null,
        ile_entry_no int not null,
        outcode_id int null,
        country_id int null,
        value_entry_original int null,
        addTS datetime2(3) not null,
        updateTS datetime2(3) not null
    constraint PK__Item_Ledger_Entry primary key (company_id, ile_entry_no)
    )
go

create index IX__C09 on ext.Item_Ledger_Entry (country_id)
go

alter table ext.Item_Ledger_Entry add constraint DF__Item_Ledger_Entry__addTS default getutcdate() for addTS
go

alter table ext.Item_Ledger_Entry add constraint DF__Item_Ledger_Entry__updateTS default getutcdate() for updateTS
go

CREATE NONCLUSTERED INDEX IX__BE8
ON [ext].[Item_Ledger_Entry] ([company_id],[country_id])
INCLUDE ([outcode_id],[updateTS])
WHERE ([country_id] is null)
go