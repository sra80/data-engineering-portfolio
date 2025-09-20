create or alter function [db_sys].[fn_set_process_flag]
	(
		@frequency_unit nvarchar(8),
		@frequency_value int,
		@last_processed datetime2(0),
		@start_month int,
		@start_day int,
		@start_dow int,
		@start_hour int,
		@start_minute int,
		@end_month int,
		@end_day int,
		@end_dow int,
		@end_hour int,
		@end_minute int,
		@utcdatetime datetime2(0) = null
	)

returns bit

as

begin

set @utcdatetime = dateadd(minute,5,isnull(@utcdatetime,getutcdate()))

declare @process bit = 0, @process0 bit = 0, @process1 bit = 0, @process2 bit = 0, @process3 bit = 0, @process4 bit = 1, @timezone nvarchar(32) = 'GMT Standard Time'

if
    (
        @frequency_unit is null
	and @frequency_value is null
    and @last_processed is null
	and @start_month is null
    and @start_day is null
	and @start_dow is null
	and @start_hour is null
	and @start_minute is null
	and @end_month is null
	and @end_day is null
	and @end_dow is null
	and @end_hour is null
	and @end_minute is null
    )
set @process4 = 0

declare 
	 @gg_time datetime2(0) = dateadd(minute,datediff(minute,@utcdatetime at TIME ZONE @timezone,@utcdatetime),@utcdatetime) 

set @gg_time = convert(datetime2(0),dateadd(second,-datepart(second,@gg_time),@gg_time))

declare
	 @gg_year int = datepart(year,@gg_time)
	,@gg_month int = datepart(month,@gg_time)
	,@gg_day int = datepart(day,@gg_time)
	,@gg_dow int = datepart(dw,@gg_time)
	,@gg_hour int = datepart(hour,@gg_time)
	,@gg_minute int = datepart(minute,@gg_time)

set @gg_time = datetimefromparts(@gg_year,@gg_month,@gg_day,@gg_hour,@gg_minute,0,0)

if @start_month is null set	@start_month = @gg_month
if @start_day is null set @start_day = @gg_day
if @start_dow is null set @start_dow = @gg_dow
if @start_hour is null set @start_hour = @gg_hour
if @start_minute is null set @start_minute = @gg_minute
if @end_month is null set @end_month = @gg_month
if @end_day is null set @end_day = @gg_day
if @end_dow is null set @end_dow = @gg_dow
if @end_hour is null set @end_hour = @gg_hour
if @end_minute is null set @end_minute = @gg_minute

declare @start_time datetime2(0) = datetimefromparts(@gg_year,@start_month,@start_day,@start_hour,@start_minute,0,0)
declare @end_time datetime2(0) = datetimefromparts(@gg_year,@end_month,@end_day,@end_hour,@end_minute,0,0)

set @frequency_unit = lower(@frequency_unit)

if right(@frequency_unit,1) = 's' set @frequency_unit = left(@frequency_unit,len(@frequency_unit)-1)

if @last_processed is null set @process0 = 1 else set @last_processed = dateadd(minute,-datepart(minute,@last_processed)%5,dateadd(second,-datepart(second,@last_processed),dateadd(minute,datediff(minute,@last_processed at TIME ZONE @timezone,@last_processed),@last_processed)))
if (@frequency_unit = 'year' or /**/ @frequency_unit = 'week') and datediff(year,@last_processed,@gg_time) >= @frequency_value set @process0 = 1
if (@frequency_unit = 'month' or /**/ @frequency_unit = 'week') and datediff(month,@last_processed,@gg_time) >= @frequency_value set @process0 = 1
if @frequency_unit = 'week' and datediff(week,@last_processed,@gg_time) >= @frequency_value set @process0 = 1
if @frequency_unit = 'day' and datediff(day,@last_processed,@gg_time) >= @frequency_value set @process0 = 1
if @frequency_unit = 'hour' and datediff(hour,@last_processed,@gg_time) >= @frequency_value set @process0 = 1
if @frequency_unit = 'minute' and datediff(minute,@last_processed,@gg_time) >= @frequency_value set @process0 = 1

if @gg_time >= @start_time and @gg_time <= @end_time set @process1 = 1
if @gg_dow >= @start_dow and @gg_dow <= @end_dow set @process3 = 1 --

if @frequency_unit = 'month' if @gg_time >= db_sys.fn_dow_ofMonth_ofWeek(@gg_time,1,@start_dow) set @process2 = 1 else set @process2 = 0 else set @process2 = 1

if @process0 = 1 and @process1 = 1 and @process2 = 1 and @process3 = 1 and @process4 = 1 set @process = 1

return @process

end
GO
