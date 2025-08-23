create or alter procedure price_tool_feed.sp_import_export_message
  (
    @logic_app_id nvarchar(36) = null,
    @place_holder_session uniqueidentifier = null,
    @is_test bit = 0
  )

as

set nocount on

declare @place_holder uniqueidentifier = newid(), @auditLog_ID int

exec db_sys.sp_auditLog_start @eventType = 'Procedure',@eventName='price_tool_feed.sp_import_export_message',@eventVersion='00',@placeHolder_ui=@place_holder,@logicApp_ID=@logic_app_id,@placeHolder_session=@place_holder_session

select @auditLog_ID = ID from db_sys.auditLog where place_holder = @place_holder

declare @count int, @original_entry_count int, @message nvarchar(max)

select @count = sum(1), @original_entry_count = sum(original_entry_count) from price_tool_feed.import_filelist where logic_app_id = @logic_app_id

if @count = 1

  begin

    select @message = concat('The file ',blob_name,' has been processed') from price_tool_feed.import_filelist where logic_app_id = @logic_app_id

    if @original_entry_count = 0 set @message += ', as there are not any new entries, no data has been imported into NAV.'

    if @original_entry_count = 1 set @message += ', 1 entry is new and will be imported into NAV'

    if @original_entry_count > 1 set @message += concat(', ',format(@original_entry_count,'###,###,##0'),' entries are new and will be imported into NAV')
    
    if @original_entry_count > 0 set @message += ', further communication will be posted in the event there are any issues.'

  end

  if @count > 1

    begin

      set @message = 'The following files have been processed, further communication will be posted in the event there are any issues:<ul>'

      select @message += concat('<li>',blob_name,' (',format(original_entry_count,'###,###,##0'),' imported)</li>') from price_tool_feed.import_filelist where logic_app_id = @logic_app_id

      set @message += '</ul>'

    end

  if @count > 0 and @is_test = 0

    begin

      exec db_sys.sp_email_notifications
        @subject = 'Yieldigo Import Status Update',
        @bodyIntro = @message,
        @auditLog_ID = @auditLog_ID,
        @is_team_alert = 1,
        @tnc_id = 1

      exec db_sys.sp_email_notifications
        @subject = 'Yieldigo Import Status Update',
        @bodyIntro = @message,
        @auditLog_ID = @auditLog_ID,
        @is_team_alert = 1,
        @tnc_id = 7

      update price_tool_feed.import_filelist set is_done = 1 where logic_app_id = @logic_app_id

      exec db_sys.sp_auditLog_procedure @procedureName = 'price_tool_feed.sp_export_check', @check_disable_flag = 1, @parent_procedureName = 'price_tool_feed.sp_import_export_message', @logicApp_ID = @logic_app_id, @place_holder_session = @place_holder_session

    end

  exec db_sys.sp_auditLog_end @eventDetail='Procedure Outcome: Success',@placeHolder_ui=@place_holder