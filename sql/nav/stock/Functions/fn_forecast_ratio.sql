create or alter function [stock].[fn_forecast_ratio]
    (
        @week_qty numeric(38,18),
        @base_year int = null
    )

returns table

as

return

select
    dow,
    round(dow_split + case when is_max = 1 then @week_qty - sum(dow_split) over () else 0 end,_round) dow_split
from
    (
        select 
            dow,
            round(@week_qty * dow_ratio,r._round) dow_split,
            r._round,
            case when dow_ratio = max(dow_ratio) over () then 1 else 0 end is_max 
        from 
            stock.forecast_ratio
        outer apply
            (
                select 
                    len(rtrim(parsename(@week_qty,1),'0')) _round
            ) r
        where 
            base_year = (select max(base_year) from stock.forecast_ratio where base_year <= isnull(@base_year,year(sysdatetime())))
    ) y
GO
