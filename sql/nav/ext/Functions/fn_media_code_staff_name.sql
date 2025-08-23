create or alter function ext.fn_media_code_staff_name
    (
        @name nvarchar(255)
    )

returns nvarchar(255)

as

begin

;with ew (word) as
    (
        select
            u.value
        from
            (
                select
                    t.value,
                    t._count,
                    t._count/sum(t._count*1.0) over () _portion
                from
                    (
                        select 
                            s.value, 
                            sum(1) _count
                        from 
                            [UK$Media Code] m 
                        cross apply 
                            string_split(m.[Description],' ') s 
                        where 
                            (
                                m.[Audience] = 'STAFF'
                            ) 
                        group by 
                            s.value
                        ) t
            ) u
        where
            (
                u._portion >= 0.01
            or  try_convert(int,u.value) >= 0
            or  (
                    upper(u.value) = u.value
                and len(u.value) > 1
                )
            or  u.value in ('Dr','Mr','Ms','Miss','Mrs')
            )
    )
, l (_value, _oridinal) as
    (
        select
            v.value,
            v.ordinal
        from
            
            string_split(replace(@name,',',''),' ',1) v
        left join
            ew
        on
            (
                v.value = ew.word
            )
        where
            (
                ew.word is null
            )
    )
, f (_name, _rev) as
    (
        select
            string_agg(_value,' ') within group (order by _oridinal asc),
            0
        from
            l

        union all

        select
            string_agg(_value,' ') within group (order by _oridinal desc),
            1
        from
            l
    )

select 
    @name = _name 
from 
    f 
where 
    (
        _rev = case when charindex(', ',@name) > 0 then 1 else 0 end
    )

return @name

end