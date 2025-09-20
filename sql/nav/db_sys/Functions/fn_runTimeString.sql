CREATE function [db_sys].[fn_runTimeString]
    (
        @runtime int, 
        @time_unit nvarchar(16)
    )

returns nvarchar(64)

as

begin

declare 
    @day_div int, @day_value int, 
    @hour_div int, @hour_value int, 
    @minute_div int, @minute_value int, 
    @time_string nvarchar(64)

declare @t table (ID int identity, val int, uni nvarchar(16))

if @time_unit = 'day' set @day_div = 1
if @time_unit = 'hour' set @day_div = 24
if @time_unit = 'minute' set @day_div = 1440
if @time_unit = 'second' set @day_div = 86400

if @time_unit = 'hour' set @hour_div = 1
if @time_unit = 'minute' set @hour_div = 60
if @time_unit = 'second' set @hour_div = 3600

if @time_unit = 'minute' set @minute_div = 1
if @time_unit = 'second' set @minute_div = 60

set @day_value = @runtime/@day_div

set @runtime -= @day_value*@day_div

if @day_value > 0 insert into @t (val, uni) values (@day_value, case when @day_value > 1 then 'days' else 'day' end)

set @hour_value = @runtime/@hour_div

set @runtime -= @hour_value*@hour_div

if @hour_value > 0 insert into @t (val, uni) values (@hour_value, case when @hour_value > 1 then 'hours' else 'hour' end)

set @minute_value = @runtime/@minute_div

set @runtime -= @minute_value*@minute_div

if @minute_value > 0 insert into @t (val, uni) values (@minute_value, case when @minute_value > 1 then 'minutes' else 'minute' end)

if @runtime > 0 insert into @t (val, uni) values (@runtime, case when @runtime > 1 then 'seconds' else 'second' end)

select @time_string = convert(nvarchar,val) + ' ' + uni + case when lead(uni,1) over (order by ID) is null then '' else case when lead(uni,2) over (order by ID) is null then ' and ' else ', ' end end from @t

return @time_string

end
GO
