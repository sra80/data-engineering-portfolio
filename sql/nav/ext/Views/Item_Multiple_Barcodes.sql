create view ext.Item_Multiple_Barcodes

as

select
    icr.[Item No_] Item,
    string_agg(icr.[Cross-Reference No_], ', ') Barcodes
from
    [UK$Item Cross Reference] icr
join
    [UK$Item] i
on
    (
        icr.[Item No_] = i.No_
    )
where
    (
        icr.[Cross-Reference Type No_] = 'GS EAN13'
    and try_convert(int,left(icr.[Cross-Reference No_],1)) > 0
    and icr.[Discontinue Bar Code] = 0
    and i.[Status] in (0,1,4)
    )
group by
    icr.[Item No_]
having
    sum(1) > 1
GO
