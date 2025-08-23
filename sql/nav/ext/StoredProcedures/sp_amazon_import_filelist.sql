create or alter procedure ext.sp_amazon_import_filelist
    (
        @filelist nvarchar(max),
        @place_holder_session uniqueidentifier,
        @logicApp_ID nvarchar(36)
    )

as

set nocount on

declare @place_holder uniqueidentifier = newid(), @eventDetail nvarchar(64), @auditLog_ID int

exec db_sys.sp_auditLog_start @eventType = 'Procedure',@eventName='hs-bi-datawarehouse-amazon (ext.sp_amazon_import_filelist)',@eventVersion='00',@placeHolder_ui=@place_holder,@placeHolder_session=@place_holder_session,@logicApp_ID=@logicApp_ID

select @auditLog_ID = ID from db_sys.auditLog where place_holder = @place_holder

begin try

    insert into ext.amazon_import_filelist (file_name, [name], LastModified, auditLog_ID)
    select
        json_value(y.value,'$.Path'),
        json_value(y.value,'$.Name'),
        json_value(y.value,'$.LastModified'),
        @auditLog_ID
    from
        openjson(@filelist) x
    cross apply
        openjson(x.value) y
    where
        (
            json_value(y.value,'$.MediaType') = 'text/plain'
        and json_value(y.value,'$.Name') not in (select [name] from ext.amazon_import_filelist)
        )

    set @eventDetail = 'Procedure Outcome: Success'

end try

begin catch

    insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage, report_error) values ('ext.sp_amazon_import_filelist', @auditLog_ID, error_line(), error_message(), 1)

    set @eventDetail = 'Procedure Outcome: Failed'

end catch

exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@place_holder