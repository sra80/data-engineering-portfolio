create function db_sys.fn_eoweek
    (
        @date date
    )

returns date

as

begin

if 
    year(dateadd(day,7-datepart(dw,@date),@date)) > year(@date) 
set 
    @date = datefromparts(year(@date),12,31) 
else 
    set @date = dateadd(day,7-datepart(dw,@date),@date)

return @date

end
GO
