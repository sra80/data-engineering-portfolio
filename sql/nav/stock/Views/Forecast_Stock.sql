create or alter view [stock].[Forecast_Stock]

as

select
    convert(bit,0) is_sub,
    isnull(f._location,sales._location) [Location Code],
    isnull(f.sku,sales.item_id) [Item No_],
    isnull(f._date,sales._date) forecast_date,
    convert(date,getdate()) _version_date,
    -1 _version_key,
    isnull(f.forecast_qty,0) _forecast_qty,
    0 subs_qty,
    isnull(sales.sales,0) actual_qty
from
    (
        select
            _date,
            isnull(loa.location_id,forecast_current.location_id) _location,
            item_id sku,
            quantity forecast_qty
        from
            stock.forecast_current
        left join
            anaplan.location_overide_aggregate loa
        on
            (
                loa.location_ID_overide = forecast_current.location_id
            and loa.distribution_loc = 1
            )
    ) f
full join
    (
        select
            isnull(loa.location_id,sales.key_location) _location,
            dateadd(day,x.dow-datepart(dw,f.foweek),f.foweek) _date,
            sales.key_item item_id,
            sum(x.dow_split) sales
        from
            anaplan.sales
        left join
            anaplan.location_overide_aggregate loa
        on
            (
                loa.location_ID_overide = sales.key_location
            and loa.distribution_loc = 1
            )
        cross apply 
            stock.fn_forecast_ratio(sales.units,default) x
        cross apply
            (
                select
                    db_sys.fn_datefrom_year_week(x._year,x._week,1) foweek
                from
                    (
                        values
                            (
                                    sales.key_date/100,
                                    sales.key_date%100
                            )
                    )
                        as
                            x
                                (
                                    _year, 
                                    _week
                                )
            ) f
        join
            ext.Platform_Grouping pg
        on
            (
                sales.key_demand_channel = pg.ID
            )
        where
            (
                pg.is_sub = 0
            )
        group by
            isnull(loa.location_id,sales.key_location),
            dateadd(day,x.dow-datepart(dw,f.foweek),f.foweek),
            sales.key_item
    ) sales
on
    (
        f._location = sales._location
    and f.sku = sales.item_id
    and f._date = sales._date
    )
where
    (
        isnull(f._date,sales._date) >= dateadd(week,-12,getutcdate())
    and isnull(f._date,sales._date) < dateadd(year,2,getutcdate())
    )

union all

select
    convert(bit,1) is_sub,
    isnull(s._location,sales._location) [Location Code],
    isnull(s.sku,sales.item_id) [Item No_],
    isnull(s._date,sales._date) forecast_date,
    convert(date,getdate()) _version_date,
    -1 _version_key,
    isnull(s.subs_qty,0) _forecast_qty,
    isnull(s.subs_qty,0) subs_qty,
    isnull(sales.sales,0) actual_qty
from
    (
        select
            u._date,
            u._location,
            u.sku,
            sum(u.subs_qty) subs_qty
        from
            (
                select
                    ext.fn_subscription_date_move(isnull(loa.company_id,l.company_id),s.ndd) _date,
                    isnull(loa.location_id,s.location_id) _location,
                    s.item_id sku,
                    s.quantity subs_qty
                from
                    stock.forecast_subscriptions s
                join
                    ext.Location l
                on
                    (
                        s.location_id = l.ID
                    )
                left join
                    anaplan.location_overide_aggregate loa
                on
                    (
                        loa.location_ID_overide = s.location_id
                    and loa.subscription_loc = 1
                    )
                where
                    (
                        row_version = (select row_version from stock.forecast_subscriptions_version where is_current = 1)
                    and rv_sub = 0
                    and s.ndd >= db_sys.foweek(getutcdate(),0)
                    )

                union all

                select
                    s.ndd _date,
                    isnull(loa.location_id,s.location_id) _location,
                    s.item_id sku,
                    s.quantity subs_qty
                from
                    stock.forecast_subscriptions s
                left join
                    anaplan.location_overide_aggregate loa
                on
                    (
                        loa.location_ID_overide = s.location_id
                    and loa.subscription_loc = 1
                    )
                join
                    (
                        select
                            fs.ndd,
                            fs.item_id,
                            max(row_version) row_version
                        from
                            stock.forecast_subscriptions fs
                        where
                            (
                                fs.rv_sub = 0
                            )
                        group by
                            fs.ndd,
                            fs.item_id
                    ) last_rv
                on
                    (
                        s.row_version = last_rv.row_version
                    and s.ndd = last_rv.ndd
                    and s.item_id = last_rv.item_id
                    )
                where
                    (
                        s.rv_sub = 0
                    and s.ndd < db_sys.foweek(getutcdate(),0)
                    )
            ) u
        group by
            u._date,
            u._location,
            u.sku
    ) s
full join
    (
        select
            isnull(loa.location_id,sales.key_location) _location,
            dateadd(day,x.dow-datepart(dw,f.foweek),f.foweek) _date,
            sales.key_item item_id,
            sum(x.dow_split) sales
        from
            anaplan.sales
        left join
            anaplan.location_overide_aggregate loa
        on
            (
                loa.location_ID_overide = sales.key_location
            and loa.subscription_loc = 1
            )
        cross apply 
            stock.fn_forecast_ratio(sales.units,default) x
        cross apply
            (
                select
                    db_sys.fn_datefrom_year_week(x._year,x._week,1) foweek
                from
                    (
                        values
                            (
                                    sales.key_date/100,
                                    sales.key_date%100
                            )
                    )
                        as
                            x
                                (
                                    _year, 
                                    _week
                                )
            ) f
        join
            ext.Platform_Grouping pg
        on
            (
                sales.key_demand_channel = pg.ID
            )
        where
            (
                pg.is_sub = 1
            )
        group by
            isnull(loa.location_id,sales.key_location),
            dateadd(day,x.dow-datepart(dw,f.foweek),f.foweek),
            sales.key_item
    ) sales
on
    (
        s._location = sales._location
    and s.sku = sales.item_id
    and s._date = sales._date
    )
where
    (
        isnull(s._date,sales._date) >= dateadd(week,-12,getutcdate())
    and isnull(s._date,sales._date) < dateadd(year,2,getutcdate())
    )
GO
