CREATE function db_sys.fn_minus_min0
    (
        @x float
    )

returns float

as

begin

if @x < 0 set @x = 0

return @x

end
GO
