create function db_sys.static_year
    (
        @date date,
        @interval int
    )

returns date

as

begin

return datefromparts(year(@date)+@interval,1,1)

end
GO
