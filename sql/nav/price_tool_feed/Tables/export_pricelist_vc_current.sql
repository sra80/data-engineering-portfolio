create table price_tool_feed.export_pricelist_vc_current
    (
      logic_app_id nvarchar(36) not null,
      id int not null
    constraint PK__export_pricelist_vc_current_vc primary key (logic_app_id)
    )
go