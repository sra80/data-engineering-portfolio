create or alter function [db_sys].[fn_datediff_string]
    (
        @time_from datetime,
        @time_to datetime,
        @granularity int = 1 /*0 = milliseconds, 1 = seconds, 2 = minutes, 3 = hours, 4 = days, 5 = auto*/
    )

returns nvarchar(64)

as

begin

declare 
    @runTime int,
    @day_value int, 
    @hour_value int, 
    @minute_value int, 
    @ms_value int,
    @time_string nvarchar(64) = ''

if @time_from is null set @time_string = '@time_from is null'
if @time_to is null set @time_string = '@time_to is null'

if @time_from > 0 and @time_to > 0

begin

set @runTime = datediff(second,@time_from,@time_to)

if @runtime < 86400 select @ms_value = datediff(millisecond,@time_from,@time_to)%1000

if @runTime < 0 set @time_string = 'Negative datediff'

declare @t table (ID int identity, val int, uni nvarchar(16), granularity int)

set @day_value = @runtime/86400

set @runtime -= @day_value*86400

if @day_value > 0 insert into @t (val, uni, granularity) values (@day_value, case when @day_value > 1 then 'days' else 'day' end, 4)

set @hour_value = @runtime/3600

set @runtime -= @hour_value*3600

if @hour_value > 0 insert into @t (val, uni, granularity) values (@hour_value, case when @hour_value > 1 then 'hours' else 'hour' end, 3)

set @minute_value = @runtime/60

set @runtime -= @minute_value*60

if @minute_value > 0 insert into @t (val, uni, granularity) values (@minute_value, case when @minute_value > 1 then 'minutes' else 'minute' end, 2)

if @runtime > 0 insert into @t (val, uni, granularity) values (@runtime, case when @runtime > 1 then 'seconds' else 'second' end, 1)

if @ms_value > 0 insert into @t (val, uni, granularity) values (@ms_value, case when @ms_value > 1 then 'milliseconds' else 'millisecond' end, 0)

if @granularity = 5 select @granularity = granularity from @t order by granularity offset 0 rows

select @time_string += convert(nvarchar,val) + ' ' + uni + case when lead(uni,1) over (order by ID) is null then '' else case when lead(uni,2) over (order by ID) is null then ' and ' else ', ' end end from @t where ID < 4 and granularity >= @granularity

/*0 = milliseconds, 1 = seconds, 2 = minutes, 3 = hours, 4 = days*/

declare @unit nvarchar(16)

if @granularity = 0 set @unit = 'millisecond'
if @granularity = 1 set @unit = 'second'
if @granularity = 2 set @unit = 'minute'
if @granularity = 3 set @unit = 'hour'
if @granularity = 4 set @unit = 'day'

end

return isnull(nullif(@time_string,''),concat('Less than a ',@unit))

end
GO
