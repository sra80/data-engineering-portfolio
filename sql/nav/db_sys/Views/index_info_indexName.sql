CREATE view [db_sys].[index_info_indexName]

as

with x as
    (
        select
            1 c,
            left(newid(),3) ix

        union all

        select
            c+1 c,
            left(newid(),3) ix
        from
            x
        where
            c < 100

    )

select top 1
    concat('IX__',x.ix) indexName
from
    x
left join
    sys.indexes s
on
    (
        concat('IX__',x.ix) = s.name
    )
left join
    db_sys.index_info h
on
    (
        concat('IX__',x.ix) = h.indexName
    )
where
    (
        s.name is null
    and h.indexName is null
    )
GO
