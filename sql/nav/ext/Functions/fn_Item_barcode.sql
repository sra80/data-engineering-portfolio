create or alter function ext.fn_Item_barcode
    (
        @item_id int
    )

returns bigint

as

begin

declare @barcode bigint

select top 1
    @barcode = try_convert(bigint,icr.[Cross-Reference No_])
from
    hs_consolidated.[Item Cross Reference] icr
join
    ext.Item i
on
    (
        icr.company_id = i.company_id
    and icr.[Item No_] = i.No_
    )
where
    (
        icr.[Discontinue Bar Code] = 0
    and icr.[Cross-Reference Type] = 3
    and icr.[Cross-Reference Type No_] = 'GS EAN13'
    and try_convert(int,left(icr.[Cross-Reference No_],1)) > 0
    and i.ID = @item_id
    )
order by
    icr.[timestamp] desc

return @barcode

end