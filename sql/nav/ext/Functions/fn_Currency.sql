--ext.fn_Currency (function)

create   function ext.fn_Currency
    (
        @code nvarchar(10)
    )

returns int

as

begin

declare @ID int

select @ID = ID from ext.Currency where lower(Code) = lower(@code)

return @ID

end
GO
