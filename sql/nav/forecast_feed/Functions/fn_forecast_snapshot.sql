create or alter function forecast_feed.fn_forecast_snapshot
    (
        @date date
    )

returns table

as

return

    select
        x._year,
        x._week,
        x.demand_channel,
        x._customer,
        x.sales_channel,
        x._location,
        x.sku,
        x.quantity
    from
        forecast_feed.forecast x
    join
        (
            select
                _year,
                _week,
                demand_channel,
                _customer,
                sales_channel,
                _location,
                sku,
                max(row_version) row_version
            from
                forecast_feed.forecast
            where
                (
                    addedTSUTC <= @date
                and db_sys.fn_datefrom_year_week(_year,_week,1) > @date
                )
            group by
                _year,
                _week,
                demand_channel,
                _customer,
                sales_channel,
                _location,
                sku
        ) y
    on
        (
            x._year = y._year
        and x._week = y._week
        and x.demand_channel = y.demand_channel
        and x._customer = y._customer
        and x.sales_channel = y.sales_channel
        and x._location = y._location
        and x.sku = y.sku
        and x.row_version = y.row_version
        )