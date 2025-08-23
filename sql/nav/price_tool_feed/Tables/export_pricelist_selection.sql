create table price_tool_feed.export_pricelist_selection
    (
        ep_vc int not null,
        external_id uniqueidentifier not null,
        price_group_id int not null
    constraint PK__export_pricelist_selection primary key (ep_vc, external_id, price_group_id)
    )
go

alter table price_tool_feed.export_pricelist_selection add constraint FK__export_pricelist_selection__ep_vc foreign key (ep_vc) references price_tool_feed.export_pricelist_vc (id)
go

-- alter table price_tool_feed.export_pricelist_selection add constraint FK__export_pricelist_selection__external_id__price_group_id foreign key (external_id, price_group_id) references price_tool_feed.export_pricelist (external_id, price_group_id)
-- go