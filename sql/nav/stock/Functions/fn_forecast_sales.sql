
CREATE function [stock].[fn_forecast_sales]
    (
        @item_id int,
        @location_id int,
        @forecast_open_date date,
        @forecast_close_date date
    )

returns table

as

return

select
    db_sys.fn_divide(sum(-r.dow_split),datediff(day,@forecast_open_date,isnull(@forecast_close_date,datefromparts(year(getutcdate())+1,12,31))),0) forecast_daily_sales,
    sum(-r.dow_split) forecast_total_sales
from
    anaplan.forecast f
cross apply
    stock.fn_forecast_ratio(f.quantity,default) r
cross apply
    (
        select
            iteration
        from
            db_sys.iteration
        where
            iteration.iteration <= datediff(day,@forecast_open_date,isnull(@forecast_close_date,datefromparts(year(getutcdate())+1,12,31)))
    ) iteration
where
    (
        f.is_current = 1
    and f._location = @location_id
    and f.sku = @item_id
    and f._year = datepart(year,dateadd(day,iteration.iteration,@forecast_open_date))
    and f._week = datepart(week,dateadd(day,iteration.iteration,@forecast_open_date))
    and r.dow = datepart(dw,dateadd(day,iteration.iteration,@forecast_open_date))
    )
GO
