CREATE function db_sys.foweek
    (
        @date date,
        @offset int = 0
    )

returns date

as

begin

return dateadd(week,@offset,dateadd(day,-datepart(dw,@date)+1,@date))

end
GO
