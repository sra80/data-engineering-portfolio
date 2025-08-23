CREATE function db_sys.fn_round_by_sample
    (
        @sample_value float,
        @actual_value float
    )

returns float

as

begin

    if @sample_value is null set @sample_value = @actual_value

    if 
        charindex('.',reverse(@sample_value))-1 < 0 set @actual_value = round(@actual_value,0)
    else
         set @actual_value = round(@actual_value,charindex('.',reverse(@sample_value))-1)

return @actual_value

end
GO
