

CREATE function [ext].[fn_datediff]
    (
         @start date
        ,@weeks int
    )

returns @t table (d int, w int, m int, q int, y int)

as

begin

declare @end_date date = dateadd(week,@weeks,@start)

declare @d int = 0, @w int = 0, @m int = 0, @q int = 0, @y int = 0

declare @part_d int, @part_m int, @part_y int, @eom_d int

set @part_d = datepart(day,@start)
set @part_m = datepart(month,@start)
set @part_y = datepart(year,@start)

declare @d_w int = 0, @d_m int = 0, @d_y int = 0, @m_q int = 0

while @start < @end_date

begin

if year(@start) > @part_y and month(@start) = @part_m and day(@start) = @part_d set @y += 1

--leap year handler
if @part_y % 4 = 0 and year(@start) % 4 > 0 and @part_m = 2 and month(@start) = @part_m and @part_d = 29 and day(@start) = 28 set @y += 1

set @eom_d = datepart(day,eomonth(@start))

set @d += 1

if @d_w = 6 begin set @d_w = 0 set @w += 1 end else set @d_w += 1

if @d_m+1 = @eom_d begin set @d_m = 0 set @m +=1 set @m_q += 1 end else set @d_m += 1

if @m_q = 3 begin set @m_q = 0 set @q +=1 end

set @start = dateadd(day,1,@start)

end

insert into @t (d,w,m,q,y) values (@d,@w,@m,@q,@y)

return 

end
GO
