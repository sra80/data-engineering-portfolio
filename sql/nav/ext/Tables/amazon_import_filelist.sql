create table ext.amazon_import_filelist
    (
        [id] int identity(0,1) not null,
        [file_name] nvarchar(255) not null,
        [name] nvarchar(255) not null,
        [LastModified] datetime2(0) not null,
        [addTS] datetime2(3) not null,
        [importTS] datetime2(3) null,
        [auditLog_ID] int null,
    constraint PK__amazon_filelist primary key ([id])
    )
go

alter table ext.amazon_import_filelist add constraint DF__amazon_import_filelist__addTS default getutcdate() for [name]
go

alter table ext.amazon_import_filelist add constraint DF__amazon_import_filelist__name default ext.fn_amazon_import_filename([file_name]) for [name]
go

create unique index IX__FF3 on ext.amazon_import_filelist ([file_name])
go

create unique index IX__A6D on ext.amazon_import_filelist ([name])
go