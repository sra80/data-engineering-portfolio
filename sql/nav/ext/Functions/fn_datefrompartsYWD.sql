
CREATE function [ext].[fn_datefrompartsYWD]
    (
        @y int, @w int, @d int
    )

returns date

as

begin

if @y = 0 set @y = 1900

if @w = 0 set @w = 1

declare @out date = dateadd(week,@w-1,datefromparts(@y,1,1))

set @out = dateadd(day,-(datepart(dw,@out)-@d),@out)

if datepart(year,@out) < @y set @out = datefromparts(@y,1,1)

if datepart(year,@out) > @y set @out = datefromparts(@y,12,31)

return @out

end
GO
