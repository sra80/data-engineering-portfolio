create or alter procedure [forecast_feed].[sp_forecast_load]
    (
        @run_id uniqueidentifier = null
    )

as

set nocount on

declare @procedureName nvarchar(64) = 'forecast_feed.sp_forecast_load'

declare @place_holder uniqueidentifier = newid(), @auditLog_ID int, @parent_auditLog_ID int, @eventDetail nvarchar(64)

exec db_sys.sp_auditLog_start @eventType = 'Procedure',@eventName=@procedureName,@eventVersion='00',@placeHolder_ui=@place_holder,@placeHolder_session=@run_id

select @auditLog_ID = ID from db_sys.auditLog where eventDetail = convert(nvarchar(36),@place_holder)

select @parent_auditLog_ID = auditLog_ID from db_sys.auditLog_dataFactory where run_ID = @run_id

        if @auditLog_ID > 0 and @parent_auditLog_ID > 0 and (select isnull(sum(1),0) from db_sys.auditLog_procedure_dependents where auditLog_ID = @auditLog_ID) = 0

        insert into db_sys.auditLog_procedure_dependents (parent_auditLog_ID, auditLog_ID)
        values (@parent_auditLog_ID, @auditLog_ID)

begin try

    truncate table forecast_feed.forecast_stage2

    insert into forecast_feed.forecast_stage2 (_year, _week, demand_channel, _customer, sales_channel, _location, sku, quantity)
    select 
        try_convert(int,s1.[2]) _year, 
        try_convert(int,s0.[2]) _week, 
        stage_forecast.demand_channel, 
        stage_forecast._customer, 
        (select ID from ext.Dimension_Value where [Dimension Code] = 'SALE.CHANNEL' and Code = stage_forecast.sales_channel) sales_channel, 
        stage_forecast._location, 
        stage_forecast.sku, 
        stage_forecast.quantity
    from 
        forecast_feed.stage_forecast
    cross apply
        db_sys.string_split(stage_forecast._time,' ') s0
    cross apply
        db_sys.string_split(s0.[3],'Y') s1
    where 
        (
            try_convert(int,s0.[2]) > 0
        and try_convert(int,s1.[2]) > 0
        and stage_forecast.demand_channel >= 0
        and abs(stage_forecast._customer) >= 0
        and (select ID from ext.Dimension_Value where [Dimension Code] = 'SALE.CHANNEL' and Code = stage_forecast.sales_channel) >= 0
        and stage_forecast._location >= 0
        and stage_forecast.sku >= 0
        )

    --clean-up year, add the millenium
    update
        forecast_feed.forecast_stage2
    set
    _year = year(getdate())-year(getdate())%1000+_year
    where
        _year/1000 = 0

    update f set
        f.reviewedTSUTC = sysdatetime(), f.is_current = case when f.quantity = s.quantity then f.is_current else 0 end
    from
        forecast_feed.forecast f
    join
        ( /***added 20/07/2023, keeps latest forecast for historic periods as current (forecast is from the current week onwards)***/
            select
                _year,
                _week
            from
                forecast_feed.forecast_stage2
            group by
                _year,
                _week
        ) forecast_window
    on
        (
            f._year = forecast_window._year
        and f._week = forecast_window._week
        )
    left join
        forecast_feed.forecast_stage2 s
    on
        (
            f.is_current = 1
        and f._year = s._year
        and f._week = s._week
        and f.demand_channel = s.demand_channel
        and f._customer = s._customer
        and f.sales_channel = s.sales_channel
        and f._location = s._location
        and f.sku = s.sku
        )
        
    insert into forecast_feed.forecast (row_version, _year, _week, demand_channel, _customer, sales_channel, _location, sku, quantity, foweek)
    select
        isnull(f.row_version+1,0), s._year, s._week, s.demand_channel, s._customer, s.sales_channel, s._location, s.sku, s.quantity, db_sys.fn_datefrom_year_week(s._year,s._week,1)
    from
        forecast_feed.forecast_stage2 s
    outer apply
        (
            select top 1 
                row_version, quantity
            from 
                forecast_feed.forecast f 
            where 
                (
                    f._year = s._year
                and f._week = s._week
                and f.demand_channel = s.demand_channel
                and f._customer = s._customer
                and f.sales_channel = s.sales_channel
                and f._location = s._location
                and f.sku = s.sku
                )
            order by 
                row_version desc
        ) f
    where
        (
            f.quantity is null
        or	s.quantity <> f.quantity
        )

    --refresh current forecast (for oos_plr)
    truncate table stock.forecast_current

    insert into stock.forecast_current (_date, location_id, item_id, quantity)
    select
        dateadd(day,x.dow-datepart(dw,f.foweek),f.foweek),
        f._location,
        f.sku,
        x.dow_split
    from 
        (
            select
                foweek,
                _location,
                sku,
                sum(quantity) quantity
            from
                forecast_feed.forecast
            where
                (
                    is_current = 1
                )
            group by
                foweek,
                _location,
                sku
        ) f
    cross apply 
        stock.fn_forecast_ratio(f.quantity,default) x


    set @eventDetail = 'Procedure Outcome: Success'

end try

begin catch

    set @eventDetail = 'Procedure Outcome: Failed'

    insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage) values (@procedureName, @auditLog_ID, error_line(), error_message())

end catch

exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@place_holder
GO
