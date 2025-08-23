create function db_sys.fn_datetime_yyyyww
    (
        @date date
    )

returns int

as

begin

return (datepart(year,@date)*100) + datepart(week,@date)

end