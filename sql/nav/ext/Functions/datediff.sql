

CREATE function [ext].[datediff]
    (
         @frequency nvarchar(1)
        ,@start_date date
        ,@end_date date
    )

returns int

as

begin

declare @is_negative bit = 0, @start date, @end date, @return int

if @start_date > @end_date 

begin set @is_negative = 1 set @start = @end_date set @end = @start_date end

else

begin set @is_negative = 0 set @start = @start_date set @end = @end_date end

declare @d int = 0, @w int = 0, @m int = 0, @q int = 0, @y int = 0

declare @part_d int, @part_m int, @part_y int, @eom_d int

set @part_d = datepart(day,@start)
set @part_m = datepart(month,@start)
set @part_y = datepart(year,@start)

declare @d_w int = 0, @d_m int = 0, @d_y int = 0, @m_q int = 0

while @start <= @end

begin

if year(@start) > @part_y and month(@start) = @part_m and day(@start) = @part_d set @y += 1

set @eom_d = datepart(day,eomonth(@start))

set @d += 1

if @d_w = 6 begin set @d_w = 0 set @w += 1 end else set @d_w += 1

if @d_m+1 = @eom_d begin set @d_m = 0 set @m +=1 if @m_q = 3 begin set @m_q = 0 set @q +=1 end else set @m_q += 1  end else set @d_m += 1

set @start = dateadd(day,1,@start)

end

if @frequency = 'd' set @return = @d
if @frequency = 'w' set @return = @w
if @frequency = 'm' set @return = @m
if @frequency = 'q' set @return = @q
if @frequency = 'y' set @return = @y

if @is_negative = 1 set @return = -@return

return @return

end
GO
