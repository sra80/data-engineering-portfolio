CREATE function [db_sys].[fn_datetime_portion]
    (
        @base_datetime datetime2(0),
        @compare_datetime datetime2(0),
        @compare_unit nvarchar(5)
    )

returns float

as

/*
 - fix to compare_units year & month, unable to add seconds to data type add changes date from parts to datetime2fromparts
*/

begin

declare @begin datetime2(0), @end datetime2(0), @return float

if @compare_unit = 'year' 

    begin

        set @begin = datefromparts(year(@base_datetime),1,1)
        set @end = dateadd(second,86399,datetime2fromparts(year(@base_datetime),12,31,0,0,0,0,0))

    end

if @compare_unit = 'month' 

    begin

        set @begin = datefromparts(year(@base_datetime),month(@base_datetime),1)
        set @end = dateadd(second,86399,convert(datetime2(0),eomonth(@base_datetime)))

    end

if @compare_unit = 'week'

    begin

        set @begin = dateadd(day,-datepart(dw,@base_datetime)+1,@base_datetime)

        if year(@begin) < year(@base_datetime) set @begin = datefromparts(year(@base_datetime),1,1)

        set @end = dateadd(day,7-datepart(dw,@base_datetime),@base_datetime)

        if year(@end) > year(@base_datetime) set @end = datefromparts(year(@base_datetime),12,31)

        set @end = dateadd(second,86399,@end)

    end

if @compare_unit = 'day'

    begin

        set @begin = @base_datetime

        set @end = dateadd(second,86399,@begin)

    end

set @return = datediff(second,@begin,@compare_datetime)/convert(float,datediff(second,@begin,@end))

if @return < 0 set @return = 0

if @return > 1 set @return = 1

return @return

end
GO
