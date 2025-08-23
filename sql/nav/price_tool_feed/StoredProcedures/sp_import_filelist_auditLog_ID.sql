create or alter procedure price_tool_feed.sp_import_filelist_auditLog_ID
    (
        @blob_id nvarchar(128),
        @place_holder uniqueidentifier,
        @place_holder_session uniqueidentifier
    )

as

set nocount on

update price_tool_feed.import_filelist set auditLog_ID = (select ID from db_sys.auditLog where place_holder = @place_holder) where blob_id = @blob_id and place_holder = @place_holder_session

if (select sum(1) from price_tool_feed.import_filelist_identifiers where place_holder = @place_holder) is null and (select sum(1) from price_tool_feed.import_filelist_identifiers where filelist_id = (select id from price_tool_feed.import_filelist where blob_id = @blob_id and place_holder = @place_holder_session)) is null

    begin

    insert into price_tool_feed.import_filelist_identifiers (place_holder, filelist_id)
    values (@place_holder, (select id from price_tool_feed.import_filelist where blob_id = @blob_id and place_holder = @place_holder_session))

    end