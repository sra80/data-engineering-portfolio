create or alter function ext.fn_amazon_import_order_id
    (
        @amazon_order_id nvarchar(32)
    )

returns table

as

return

select
    [1] [amazon_order_id_p1],
    [2] [amazon_order_id_p2],
    [3] [amazon_order_id_p3]
from
    (
        select
            try_convert(int,s.value) u,
            s.ordinal
        from
            string_split(@amazon_order_id,'-',1) s
    ) u
pivot
    (
        max(u.u)
    for
        u.ordinal in ([1],[2],[3])
    ) p