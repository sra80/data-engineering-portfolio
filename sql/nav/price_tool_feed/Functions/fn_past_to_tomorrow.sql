create or alter function price_tool_feed.fn_past_to_tomorrow
    (
        @date date, --original date
        @point_in_time date, --point in time data is processed
        @offset int = 1 --offset of @point_in_time, usually 1 day
    )

returns date

as

begin    

    select
        @date = max(d)
    from
        (
            values
                (@date),
                (dateadd(day,@offset,isnull(@point_in_time,getutcdate())))
        ) as x(d)

    return @date

end