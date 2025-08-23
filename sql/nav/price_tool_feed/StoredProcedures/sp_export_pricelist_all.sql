create or alter procedure price_tool_feed.sp_export_pricelist_all
    (
        @logicApp_ID nvarchar(36) = null
    )

as

set nocount on

if (select isnull(sum(1),0) from price_tool_feed.export_pricelist_vc where logic_app_id = @logicApp_ID) = 0

    begin

        update price_tool_feed.export_pricelist_vc set is_current = 0 where is_current = 1

        insert into price_tool_feed.export_pricelist_vc (logic_app_id, is_current)
        values (@logicApp_ID, 1)

    end

declare @item_id int, @vc_id int

declare @list table (item_id int)

select @vc_id = id from price_tool_feed.export_pricelist_vc where logic_app_id = @logicApp_ID

insert into @list (item_id)
select distinct
    item_id
from
    price_tool_feed.import_pricelist
where
    (
        external_id_original is null
    and is_processed = 0
    )

while (select isnull(sum(1),0) from @list) > 0

begin

    select top 1 @item_id = item_id from @list

    exec price_tool_feed.sp_export_pricelist @item_id, @vc_id

    delete from @list where item_id = @item_id

end

update
    ip
set
    ip.is_processed = 1
from
    price_tool_feed.import_pricelist ip
join
    price_tool_feed.import_filelist f
on
    (
        ip.filelist_id = f.id
    )
where
    (
        ip.is_processed = 0
    and f.logic_app_id = @logicApp_ID
    )