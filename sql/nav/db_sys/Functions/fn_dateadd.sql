create or alter function db_sys.fn_dateadd
    (
        @frequency_unit nvarchar(16),
        @frequency_value int,
        @datetime datetime2(3)
    )

returns datetime2(3)

as

begin

if @frequency_unit = 'minute' set @datetime = dateadd(minute,@frequency_value,@datetime)

if @frequency_unit = 'hour' set @datetime = dateadd(hour,@frequency_value,@datetime)

if @frequency_unit = 'day' set @datetime = dateadd(day,@frequency_value,@datetime)

if @frequency_unit = 'week' set @datetime = dateadd(week,@frequency_value,@datetime)

if @frequency_unit = 'month' set @datetime = dateadd(month,@frequency_value,@datetime)

if @frequency_unit = 'year' set @datetime = dateadd(year,@frequency_value,@datetime)

return @datetime

end