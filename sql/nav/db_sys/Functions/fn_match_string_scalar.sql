create function db_sys.fn_match_string_scalar
    (
        @string nvarchar(max) 
    )

returns nvarchar(max)

as

begin

declare @t table (_character nvarchar, _count int, _index int identity)

declare @char int = 48, @match_string nvarchar(max) = ''

while @char <= 57

begin

insert into @t (_character, _count) values (char(@char), 0)

set @char += 1

end

set @char = 65

while @char <= 90

begin

insert into @t (_character, _count) values (char(@char), 0)

set @char += 1

end

while len(@string) > 0

begin

update @t set _count = _count + 1 where _character = upper(left(@string,1))

set @string = right(@string,len(@string)-1)

end

select 
    @match_string += case when len(@match_string) = 0 then '' else '|' end + _character + format(_count,'000')
from 
    @t
where 
    _count > 0

return @match_string

end
GO
