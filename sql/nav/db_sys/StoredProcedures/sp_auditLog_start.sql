create or alter procedure [db_sys].[sp_auditLog_start]
    (
        @eventUTCStart varchar(32) = null,
        @eventType nvarchar(32),
        @eventName nvarchar(128),
        @eventVersion nvarchar(16) = '00',
        @placeHolder nvarchar(36) = null,
        @model_script nvarchar(max) = null,
        @logicApp_ID nvarchar(36) = null,
        @placeHolder_ui uniqueidentifier = null,
        @placeHolder_session uniqueidentifier = null
    )

as

if @placeHolder is null set @placeHolder = convert(nvarchar(36),@placeHolder_ui)

if @placeHolder_ui is null set @placeHolder_ui = try_convert(uniqueidentifier,@placeHolder)

declare @eventUTCStart_dt datetime2, @auditLog_ID int, @parent_auditLog_ID int

set @eventUTCStart_dt = isnull(try_convert(datetime2,@eventUTCStart,127),getutcdate())

insert into db_sys.auditLog (eventType,eventName,eventVersion,eventDetail,place_holder,place_holder_session) values (@eventType,@eventName,@eventVersion,@placeHolder,@placeHolder_ui,isnull(@placeHolder_session,@placeHolder_ui))

select @auditLog_ID = ID from db_sys.auditLog where place_holder = @placeHolder_ui

select @parent_auditLog_ID = ID from db_sys.auditLog where place_holder = @placeHolder_session

if @parent_auditLog_ID < @auditLog_ID insert into db_sys.auditLog_procedure_dependents (parent_auditLog_ID, auditLog_ID) values (@parent_auditLog_ID, @auditLog_ID)

if (select isnull(sum(1),0) from [db_sys].[auditLog_logicApp_identifier_model] where auditLog_ID = @auditLog_ID) = 0 and @logicApp_ID is not null insert into [db_sys].[auditLog_logicApp_identifier_model] (auditLog_ID, ID) values (@auditLog_ID, @logicApp_ID)

if @placeHolder_ui is not null insert into db_sys.auditLog_sql_session (session_id, place_holder) values (@@spid, @placeHolder_ui)

if @eventType = 'Process Model' update db_sys.process_model set process_active = 1, place_holder = @placeHolder_ui where model_name = @eventName --and place_holder is null

if @eventType = 'Process Model' update db_sys.process_model_partitions set place_holder = @placeHolder_ui where model_name = @eventName and process = 1

if @eventType = 'Process Model' and @model_script is not null insert into db_sys.process_model_script_log (auditLog_ID, model_name, model_script) values ((select top 1 ID from db_sys.auditLog where place_holder = @placeHolder_ui),@eventName,@model_script)

if @eventType = 'Procedure' or @eventType = 'Procedure (Pre Model)'

    begin
    
        if (select top 1 procedureName from db_sys.procedure_schedule where procedureName = @eventName) is null insert into db_sys.procedure_schedule (procedureName, place_holder, place_holder_session) values (@eventName, @placeHolder_ui, @placeHolder_session)

        update db_sys.procedure_schedule set process_active = 1, place_holder = @placeHolder_ui, place_holder_session = isnull(@placeHolder_session,@placeHolder_ui) where procedureName = @eventName

    end

GO