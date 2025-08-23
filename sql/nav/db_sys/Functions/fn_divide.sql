CREATE function db_sys.fn_divide
    (
        @numerator float,
        @denominator float,
        @divby0_return float = 0
    )

returns float with schemabinding--, returns null on null input

as

begin

return case when @denominator = 0 then @divby0_return else @numerator/@denominator end

end
GO
