create or alter function db_sys.fn_date_thisTimeLastYear
    (
        @date date
    )

returns date

as

begin

if (year(@date)%4 = 0 and month(@date) > 2) or (year(@date)%4 = 1 and month(@date) <= 2)

    set @date = dateadd(day,-366,@date)

else

    set @date = dateadd(day,-365,@date)

return @date

end