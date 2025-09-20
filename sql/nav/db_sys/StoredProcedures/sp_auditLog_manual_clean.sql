create or alter procedure [db_sys].[sp_auditLog_manual_clean]
    (
        @ID int
    )

as

declare @place_holder uniqueidentifier

select @place_holder = place_holder from db_sys.auditLog where ID = @ID

if @place_holder is not null

begin

    update db_sys.auditLog set 
        eventUTCEnd = getutcdate(),
        eventDetail = 'Stuck procedures, auditLog entry updated by ' + lower(system_user) 
    where 
        (
            eventUTCEnd is null 
        and eventDetail = @place_holder
        and ID = @ID
        )

    update db_sys.procedure_schedule set process = 0, process_active = 0 where place_holder = @place_holder
    update db_sys.email_notifications_schedule set is_processing = 0 where place_holder = @place_holder
    update db_sys.process_model set process_active = 0 where place_holder = @place_holder

    update 
           h_pmp  
        set 
            h_pmp.process = 0,
            h_pmp.trigger_sp = 0
        from
            db_sys.process_model_partitions h_pmp
        join
            db_sys.process_model h_pm
        on
            (
                h_pmp.model_name = h_pm.model_name
            )
        where 
            (
                h_pmp.place_holder = @place_holder
            )

end
GO
