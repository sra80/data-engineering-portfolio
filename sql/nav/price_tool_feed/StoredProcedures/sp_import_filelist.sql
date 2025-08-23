create or alter procedure price_tool_feed.sp_import_filelist
    (
        @file_list nvarchar(max),
        @place_holder uniqueidentifier,
        @logic_app_id nvarchar(36) = null,
        @is_test bit = 0
    )

as

set nocount on

insert into price_tool_feed.import_filelist (blob_id, blob_name, blob_modified, place_holder, logic_app_id, is_test)
select
    json_value(k.value,'$.Id') blob_id,
    json_value(k.value,'$.Name') blob_name,
    convert(datetime2(0),json_value(k.value,'$.LastModified')) blob_modified,
    @place_holder,
    @logic_app_id,
    @is_test
from
    openjson(@file_list) j
cross apply
    openjson(j.value) k

truncate table price_tool_feed.import_filelist_identifiers

go

grant execute on price_tool_feed.sp_import_filelist to [hs-bi-datawarehouse-price_tool_feed-import]