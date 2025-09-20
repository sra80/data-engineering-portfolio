CREATE function db_sys.fn_charindex
    (
        @string nvarchar(max)
    )

returns @t table (_pos int identity, _charindex int, _char nvarchar)

as

begin

while len(@string) > 0 begin insert into @t (_charindex, _char) values (ascii(left(@string,1)), left(@string,1)) set @string = right(@string,len(@string)-1) end

return

end
GO
