create function db_sys.fn_bit_to_boolean
    (
        @bit bit
    )

returns nvarchar(5)

as

begin

return

        replace(replace(@bit,1,'True'),0,'False')

end
GO
