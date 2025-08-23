create table ext.amazon_import_recon_history
    (
        recon_auditLog_ID int not null,
        sales_line_id int not null,
        quantity int not null,
        auditLog_ID int not null,
        addTS datetime2(3) not null
    constraint PK__amazon_import_recon_history primary key (recon_auditLog_ID, sales_line_id)
    )
go

alter table ext.amazon_import_recon_history add constraint DF__amazon_import_recon_history__addTS default getutcdate() for addTS
go

create index IX__CB0 on ext.amazon_import_recon_history (auditLog_ID)
go