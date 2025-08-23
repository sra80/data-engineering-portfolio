  CREATE view marketing.Forecast

  as
  
  with fc_agg as
    (
        select 
            [Location Code] location_code,
            [Item No_] sku,
            db_sys.foweek([Forecast Date],default) wc,
            CEILING(SUM([Forecast Quantity])) forecast
        from
            [UK$Production Forecast Entry]
        where
            (
                [Production Forecast Name] = 'SALES'
            and [Location Code] in (select location_code from ext.[Location] where country = 'GB' and distribution_type = 'DIRECT')
            and [Created Date Time] < [Forecast Date]
            and nullif([Location Code],'') is not null
            )
        group by
            [Location Code],
            [Item No_],
            db_sys.foweek([Forecast Date],default)
    )

, fc_agg_ext as
    (
        select 
            location_code,
            sku, 
            wc, 
            forecast, 
            db_sys.fn_count_days_in_week(wc) day_count, 
            floor(db_sys.fn_divide(forecast,db_sys.fn_count_days_in_week(wc),default)) forecast_day, 
            forecast%db_sys.fn_count_days_in_week(wc) forecast_day_r 
        from 
            fc_agg 
    )

, fc_day as
    (
        select
            location_code,
            sku,
            wc,
            wc _date,
            forecast,
            day_count,
            1 _day,
            forecast_day + forecast_day_r forecast_now,
            forecast_day
        from
            fc_agg_ext

    union all

        select
            location_code,
            sku,
            wc,
            dateadd(day,1,_date) _date,
            forecast,
            day_count,
            _day + 1,
            forecast_day forecast_now,
            forecast_day
        from
            fc_day
        where
            _day < 7
    )

select
    _date,
    location_code,
    sku,
    forecast_now forecast
from
    fc_day
GO
