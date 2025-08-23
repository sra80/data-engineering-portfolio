create table price_tool_feed.export_pricelist_newid
    (
        external_id_root uniqueidentifier not null, --the original external_id from import_pricelist
        external_id uniqueidentifier not null, -- the newly assigned external_id
        addTS datetime2(3) not null
    constraint PK__export_pricelist_newid primary key (external_id_root, external_id)
    )
go

alter table price_tool_feed.export_pricelist_newid add constraint DF__export_pricelist_newid__addTS default getutcdate() for addTS
go