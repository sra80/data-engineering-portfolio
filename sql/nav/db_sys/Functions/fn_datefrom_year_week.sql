create or alter function [db_sys].[fn_datefrom_year_week]
    (
        @year int,
        @week int,
        @dow int = 1
    )

returns date

as

begin

declare @_date date

if @dow < 1 set @dow = 1

if @dow > 7 set @dow = 7

if @week < 1 set @week = 1

if @week > 53 set @week = 53

select top 1
    @_date = _date
from
    (
        select
            dateadd(day,iteration,datefromparts(@year,1,1)) _date
        from
            db_sys.iteration
    ) cal
where
    (
        datepart(year,_date) = @year
    and datepart(week,_date) = @week
    and (
            datepart(dw,_date) = @dow
        or  cal._date = datefromparts(@year,1,1)
        or  cal._date = datefromparts(@year,12,31)
        )
    )

return @_date

end
GO