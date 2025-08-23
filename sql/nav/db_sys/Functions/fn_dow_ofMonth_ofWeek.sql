CREATE function db_sys.fn_dow_ofMonth_ofWeek
    (
        @date date,
        @week int = 1,
        @dow int = 1
    )

returns date

--calculates the @dow (day of week) of month, aligning the week to the month e.g. if the month starts on a Wednesday, the first day of each week starts on Wednesday, useful for scheduling for something to run on the first Sunday of the month for example

as

begin

with cal as
    (
        select 
            datefromparts(year(@date),month(@date),1) d,
            datepart(dw,datefromparts(year(@date),month(@date),1)) dw,
            1 c

        union all

        select
            dateadd(day,1,d),
            dw,
            c + case when datepart(dw,dateadd(day,1,d)) = dw then 1 else 0 end
        from
            cal
        where
            (
                d < eomonth(@date)
            )

    )

select
    @date = max(d)
from
    cal
where
    (
        c = @week
    and datepart(dw,d) = @dow
    )

return @date

end
GO
