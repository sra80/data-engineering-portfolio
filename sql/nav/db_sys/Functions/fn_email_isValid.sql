CREATE function db_sys.fn_email_isValid
    (
        @email varchar(255) = 'user@example.com'
    )

returns bit

as

begin

declare @is_valid bit

;with _split as
    (
        select
            2 _index,
            len(@email) _len,
            substring(@email,1,1) _char

        union all

        select
            _index + 1,
            _len - 1,
            substring(@email,_index,1)
        from
            _split
        where
            _len > 1
        
    )

, _check as
    (
        select case when _index - (select top 1 _index from _split where _char = '@') > 1 and isnull(_index-lag(_index) over (order by _index),99) > 1 then 1 else 0 end is_valid from _split where _char = '.' and _index > (select top 1 _index from _split where _char = '@')

        union all

        select case when isnull(_index-lag(_index) over (order by _index),99) > 1 then 1 else 0 end is_valid from _split where _char = '.' and _index < (select top 1 _index from _split where _char = '@')

        union all

        select case when _count = 1 then 1 else 0 end from (select sum(1) _count from _split where _char = '@') x

        union all

        select case when _count > 0 then 0 else 1 end from (select sum(1) _count from _split where ascii(_char) <= 32 or (ascii(_char) >= 40 and ascii(_char) <= 41) or (ascii(_char) >= 58 and ascii(_char) <= 63) or (ascii(_char) >= 91 and ascii(_char) <= 94) or (ascii(_char) >= 126)) x

        union all

        select case _char when '@' then 0 when '.' then 0 else 1 end from _split where _index = 2 or _index-1 = len(@email)
    )


select @is_valid = case when sum(is_valid) = sum(1) then 1 else 0 end from _check

return @is_valid

end
GO
