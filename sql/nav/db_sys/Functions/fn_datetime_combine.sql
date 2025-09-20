create or alter function db_sys.fn_datetime_combine
    (
        @date datetime,
        @time datetime
    )

returns datetime

as

begin

    return

        datetime2fromparts
            (
                datepart(year,@date),
                datepart(month,@date),
                datepart(day,@date),
                datepart(hour,@time),
                datepart(minute,@time),
                datepart(second,@time),
                datepart(millisecond,@time),
                3
            )

end