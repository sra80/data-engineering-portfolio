create or alter procedure [forecast_feed].[sp_stock_history]
    (
        @fall_back int = 2, --number of weeks to rebuild, by default this is 2
        @is_current bit = 0,
        @sku nvarchar(20) = null,
        @run_id uniqueidentifier = null,
        @place_holder uniqueidentifier = null
    )

as

set nocount on

declare @procedureName nvarchar(64) = 'forecast_feed.sp_stock_history'

if @place_holder is null set @place_holder = newid()

declare @auditLog_ID int, @parent_auditLog_ID int, @eventDetail nvarchar(64)

exec db_sys.sp_auditLog_start @eventType = 'Procedure',@eventName=@procedureName,@eventVersion='00',@placeHolder_ui=@place_holder,@placeHolder_session=@run_id

select @auditLog_ID = ID from db_sys.auditLog where eventDetail = convert(nvarchar(36),@place_holder)

select @parent_auditLog_ID = auditLog_ID from db_sys.auditLog_dataFactory where run_ID = @run_id

        if @auditLog_ID > 0 and @parent_auditLog_ID > 0 and (select isnull(sum(1),0) from db_sys.auditLog_procedure_dependents where auditLog_ID = @auditLog_ID) = 0

        insert into db_sys.auditLog_procedure_dependents (parent_auditLog_ID, auditLog_ID)
        values (@parent_auditLog_ID, @auditLog_ID)

begin try

    --maintenance: clear out data that is out of the time scope of Anaplan
    delete from forecast_feed.stock_history where closing_date < (select max(closing_date) from forecast_feed.stock_history where datediff(year,closing_date,sysdatetime()) = 3)

    declare @date date, @date_start date = db_sys.foweek(datefromparts(year(getutcdate())-2,1,1),0), @is_new bit = 0

    if @is_current = 0

        begin

            select @date = max(closing_date) from forecast_feed.stock_history where is_current = 0 and key_batch in (select ID from ext.Item_Batch_Info where sku = isnull(@sku,sku))

            if @date > @date_start set @date = dateadd(day,1,dateadd(week,-@fall_back,@date))

            if @date is null begin set @date = @date_start set @is_new = 1 end

        end

    else

        set @date = dateadd(day,1,getutcdate())

    while (@is_current = 0 and @date < getutcdate()) or (@is_current = 1 and @date <= dateadd(day,1,getutcdate()))

    begin

            if @is_current = 0 and @is_new = 0 
                    
                delete from forecast_feed.stock_history where closing_date = dateadd(day,-1,@date) and is_current = @is_current and key_batch in (select ID from ext.Item_Batch_Info where sku = isnull(@sku,sku))
            
            if @is_current = 1

                delete from forecast_feed.stock_history where is_current = @is_current and key_batch in (select ID from ext.Item_Batch_Info where sku = isnull(@sku,sku))

            insert into forecast_feed.stock_history (is_current, key_location, key_batch, closing_date, units)
            select
                @is_current,
                x.location_ID_overide,
                isnull(x.ID,(select top 1 ID from ext.Item_Batch_Info b where b.company_id = x.company_id and b.sku = x.[Item No_] and b.variant_code = 'dummy' and b.batch_no = 'Not Provided')),
                dateadd(day,-1,@date),
                x.Quantity
            from
                (
                    select
                        ile.company_id,
                        loc.location_ID_overide,
                        ile.[Item No_],
                        ibi.ID,
                        sum(Quantity) Quantity
                    from
                        hs_consolidated.[Item Ledger Entry] ile
                    left join
                        ext.Item_Batch_Info ibi
                    on
                        (
                            ile.company_id = ibi.company_id
                        and ile.[Item No_] = ibi.sku
                        and ile.[Variant Code] = ibi.variant_code
                        and ile.[Lot No_] = ibi.batch_no
                        )
                    left join
                        forecast_feed.location_overide_aggregate loc
                    on
                        (
                            ile.company_id = loc.company_id
                        and ile.[Location Code] = loc.location_code
                        )
                    where
                        ( 
                            ile.[Posting Date] < @date
                        and ile.[Item No_] = isnull(@sku,ile.[Item No_])
                        )
                    group by
                        ile.company_id,
                        loc.location_ID_overide,
                        ile.[Item No_],
                        ibi.ID
                    having
                        sum(Quantity) > 0
            ) x

    set @date = dateadd(week,1,@date)

    end

    set @eventDetail = 'Procedure Outcome: Success'

end try

begin catch

    set @eventDetail = 'Procedure Outcome: Failed'

    insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage) values (@procedureName, @auditLog_ID, error_line(), error_message())

end catch

exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@place_holder
GO
