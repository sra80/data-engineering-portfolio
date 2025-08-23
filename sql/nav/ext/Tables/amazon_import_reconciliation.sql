create table ext.amazon_import_reconciliation
    (
        [sales_line_id] int not null,
        [ile_entry_no] int not null, --foreign key constraint not added to prevent possible replication issues
        [quantity] int not null,
        [addTS] datetime2(3)
    constraint PK__amazon_import_reconciliation primary key ([sales_line_id], [ile_entry_no])
    )
go

alter table ext.amazon_import_reconciliation add constraint FK__amazon_import_reconciliation__sales_line_id foreign key ([sales_line_id]) references ext.amazon_import_sales_line ([id])
go

alter table ext.amazon_import_reconciliation add constraint DF__amazon_import_reconciliation__sales_line_id default getutcdate() for [addTS]
go

create index IX__C87 on ext.amazon_import_reconciliation ([sales_line_id])
go

create unique index IX__064 on ext.amazon_import_reconciliation ([ile_entry_no]) where ([ile_entry_no] >= 0)
go

create index IX__EC7 on ext.amazon_import_reconciliation ([ile_entry_no]) where ([ile_entry_no] < 0)
go

create index IX__EDA on ext.amazon_import_reconciliation ([ile_entry_no])
go