create or alter function ext.fn_Item_Vendor_Ref
    (
        @item_id int
    )

returns nvarchar(20)

as

begin

declare @cross_ref_no nvarchar(20)

select top 1
    @cross_ref_no = icr.[Cross-Reference No_]
from
    hs_consolidated.[Item Cross Reference] icr
join
    hs_consolidated.[Item] i
on
    (
        icr.company_id = i.company_id
    and icr.[Item No_] = i.No_
    and icr.[Cross-Reference Type No_] = i.[Vendor No_]
    )
join
    ext.Item ii
on
    (
        i.company_id = ii.company_id
    and i.No_ = ii.No_
    )
where
    (
        ii.ID = @item_id
    )

return @cross_ref_no

end