create or alter function ext.fn_amazon_import_sku_nav
    (
        @sku_amazon nvarchar(32)
    )

returns nvarchar(32)

as

begin

declare @is_matched bit = 0

;with x as
    (
        select
            convert(nvarchar(32),[value]) [value],
            [ordinal],
            1 [level]
        from
            string_split(upper(@sku_amazon),'-',1)

        union all

        select
            convert(nvarchar(32),concat(x.[value],'-',y.[value])),
            y.[ordinal],
            x.[level]+1
        from
            x
        cross apply
            string_split(upper(@sku_amazon),'-',1) y
        where
            x.ordinal+1 = y.ordinal
    )

select top 1
    @sku_amazon = ii.No_, @is_matched = 1
from 
    x
join
    (
        select
            i.No_
        from
            ext.Item i
        where
            i.company_id = 1
    ) ii
on
    (
        x.[value] = ii.No_
    )
where 
    (
        [level] = [ordinal]
    )
order by
    x.[level] desc

if @is_matched = 0

    select top 1
        @sku_amazon = w.No_
    from
        (
            select
                v.No_,
                v.match_score,
                max(v.match_score) over () match_score_best
            from
                (
                    select
                        u.No_,
                        db_sys.fn_divide(sum(1) over (partition by u.No_),s.ordinal_count,0) match_score
                    from
                        (
                            select
                                r.value,
                                max(r.ordinal) over () ordinal_count
                            from
                                string_split(@sku_amazon,'-',1) r
                        ) s
                    join
                        (
                            select
                                i.No_,
                                t.value
                            from
                                ext.Item i
                            cross apply
                                string_split(i.No_,'-') t
                            where
                                (
                                    i.company_id = 1
                                )
                        ) u
                    on
                        (
                            s.value = u.value
                        )
                ) v
        ) w
    where
        (
            w.match_score = w.match_score_best
        )

return 
    @sku_amazon

end