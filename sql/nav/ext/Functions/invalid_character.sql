CREATE function ext.invalid_character
	(
		@string nvarchar(max)
	)

returns bit

as

begin

declare @invalid_chars bit = 0, @s_l int, @c int = 1

select @s_l = len(@string)

while @c < @s_l and @invalid_chars = 0

begin

--select @invalid_chars = case when UNICODE(SUBSTRING(@string,@c,1)) = 63 or (UNICODE(SUBSTRING(@string,@c,1)) <= 27 and UNICODE(SUBSTRING(@string,@c,1)) != 13) then 1 else 0 end
select @invalid_chars = case when UNICODE(SUBSTRING(@string,@c,1)) >= 32 then 0 else 1 end

set @c += 1

end

return @invalid_chars

end
GO
