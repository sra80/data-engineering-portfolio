create or alter procedure price_tool_feed.sp_export_pricelist_vc
    (
        @logicApp_ID nvarchar(36) = null,
        @place_holder uniqueidentifier = null,
        @place_holder_session uniqueidentifier = null
    )

as

set nocount on

if (select isnull(sum(1),0) from price_tool_feed.export_pricelist_vc where logic_app_id = @logicApp_ID) = 0

    begin

        update price_tool_feed.export_pricelist_vc set is_current = 0 where is_current = 1

        insert into price_tool_feed.export_pricelist_vc (logic_app_id, place_holder, place_holder_session, is_current)
        values (@logicApp_ID, @place_holder, @place_holder_session, 1)

    end

delete from price_tool_feed.export_pricelist_vc_current

insert into price_tool_feed.export_pricelist_vc_current (logic_app_id, id) select logic_app_id, id from price_tool_feed.export_pricelist_vc where logic_app_id = @logicApp_ID
go
