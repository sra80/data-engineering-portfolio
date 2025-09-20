create or alter function db_sys.fn_replace_nonAlpaNumeric
    (
        @value nvarchar(255),
        @replacement_char nvarchar(1) = '_'
    )

returns nvarchar(255)

as

begin

declare @output nvarchar(255) = ''

declare 
    @value0 nvarchar(100) = substring(@value,1,100),
    @value1 nvarchar(100) = substring(@value,101,100),
    @value2 nvarchar(100) = substring(@value,201,100)

;with c0 as
    (
        select
            2 i,
            substring(@value0,1,1) c

        union all

        select
            i+1,
            substring(@value0,i,1)
        from
            c0
        where
            i < len(@value0)+1
    )
, c1 as
    (
        select
            2 i,
            substring(@value1,1,1) c

        union all

        select
            i+1,
            substring(@value1,i,1)
        from
            c0
        where
            i < len(@value1)+1
    )
, c2 as
    (
        select
            2 i,
            substring(@value2,1,1) c

        union all

        select
            i+1,
            substring(@value2,i,1)
        from
            c0
        where
            i < len(@value2)+1
    )

select
    @output += case when patindex('%[^A-Za-z0-9]%',c) = 1 then @replacement_char else c end
from
    (
        select c from c0

        union all

        select c from c1

        union all

        select c from c2
    ) c

return @output

end