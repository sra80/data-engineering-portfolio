create view ext.Customer_Type__Mismatch__is_anon

as

select
    nav_code [Customer Type],
    c1._value [UK],
    c4._value [NL],
    c5._value [NZ],
    c6._value [IE]
from
    (
        select
            coalesce(c1.nav_code,c4.nav_code,c5.nav_code,c6.nav_code) nav_code,
            c1.is_anon c1,
            c4.is_anon c4,
            c5.is_anon c5,
            c6.is_anon c6,
            (select count(x.x) from (values(c1.is_anon),(c4.is_anon),(c5.is_anon),(c6.is_anon)) as x(x)) _count_all,
            (select count(x.x) from (values(nullif(c1.is_anon,0)),(nullif(c4.is_anon,0)),(nullif(c5.is_anon,0)),(nullif(c6.is_anon,0))) as x(x)) _count_true,
            convert(bit,round(db_sys.fn_divide((select count(x.x) from (values(nullif(c1.is_anon,0)),(nullif(c4.is_anon,0)),(nullif(c5.is_anon,0)),(nullif(c6.is_anon,0))) as x(x)),(select count(x.x) from (values(c1.is_anon),(c4.is_anon),(c5.is_anon),(c6.is_anon)) as x(x)),0),0)) _filler
        from
            (select distinct nav_code from ext.Customer_Type) base
        left join
            (select * from ext.Customer_Type where company_id = 1) c1
        on
            (
                base.nav_code = c1.nav_code
            )
        left join
            (select * from ext.Customer_Type where company_id = 4) c4
        on
            (
                base.nav_code = c4.nav_code
            )
        left join
            (select * from ext.Customer_Type where company_id = 5) c5
        on
            (
                base.nav_code = c5.nav_code
            )
        left join
            (select * from ext.Customer_Type where company_id = 6) c6
        on
            (
                base.nav_code = c6.nav_code
            )
    ) x
join
    (
        select
            convert(bit,0) _key,
            'FALSE' _value

        union all

        select
            convert(bit,1) _key,
            'TRUE' _value  
    ) c1
on
    (
        isnull(x.c1,x._filler) = c1._key
    )
join
    (
        select
            convert(bit,0) _key,
            'FALSE' _value

        union all

        select
            convert(bit,1) _key,
            'TRUE' _value  
    ) c4
on
    (
        isnull(x.c4,x._filler) = c4._key
    )
join
    (
        select
            convert(bit,0) _key,
            'FALSE' _value

        union all

        select
            convert(bit,1) _key,
            'TRUE' _value  
    ) c5
on
    (
        isnull(x.c5,x._filler) = c5._key
    )
join
    (
        select
            convert(bit,0) _key,
            'FALSE' _value

        union all

        select
            convert(bit,1) _key,
            'TRUE' _value  
    ) c6
on
    (
        isnull(x.c6,x._filler) = c6._key
    )
where
    (
        isnull(x.c1,x._filler) <> x._filler
    or  isnull(x.c4,x._filler) <> x._filler
    or  isnull(x.c5,x._filler) <> x._filler
    or  isnull(x.c6,x._filler) <> x._filler
    )
GO
