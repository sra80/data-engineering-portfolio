create or alter function db_sys.fn_outcode
    (
        @postcode nvarchar(16),
        @country_code nvarchar(2)
    )

returns int

as

begin

declare @outcode_id int = -1

select
    @outcode_id = o.id
from
    db_sys.outcode o
where
    (
        charindex(' ',@postcode) > 0
    and o.outcode = left(@postcode,charindex(' ',@postcode)-1)
    and    
        (
            o.country = @country_code
        or
            (
                (
                    @country_code = 'GB'
                or  @country_code = 'UK'
                )
            and o.country not in ('IE','ZZ')
            )
        )
    )

if @outcode_id = -1 and @country_code = 'IE'

    begin

    select
        @outcode_id = o.id
    from
        db_sys.outcode o
    where
        (
            o.outcode = left(@postcode,3)
        and o.country = @country_code
        )

    end

if @outcode_id = -1

    select top 1
        @outcode_id = o.id
    from
        db_sys.iteration i
    join
        db_sys.outcode o
    on
        left(@postcode,i.iteration) = o.outcode
    where
        (
            i.iteration > 0
        and i.iteration <= len(@postcode)
        and    
            (
                o.country = @country_code
            or
                (
                    (
                        @country_code = 'GB'
                    or  @country_code = 'UK'
                    )
                and o.country not in ('IE','ZZ')
                )
            )
        )
    order by
        i.iteration desc

return @outcode_id

end
GO