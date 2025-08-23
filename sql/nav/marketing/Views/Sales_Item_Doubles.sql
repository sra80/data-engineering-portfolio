create or alter view marketing.Sales_Item_Doubles

as

select
    i1.company_id,
    d.order_date,
    t.[Description] [Delivery Service],
    case when d.item_id_1 = d.item_id_2 then 'Same' else 'Mixed' end [Pair Type],
    concat(i1.No_,case when d.item_id_1 = d.item_id_2 then ' x 2' else concat(' & ',i2.No_) end) [Pair],
    i1.No_ [Item 1],
    i2.No_ [Item 2],
    d.units_ttl [Total Order Units],
    d.is_parcel [Has Parcel Pack Type],
    d.is_largeletter [Has Large Letter Pack Type],
    d._count,
    d.item_id_1,
    d.item_id_2,
    i1.hex_color hex_color_i1,
    i2.hex_color hex_color_i2
from
    (
        select
            order_date,
            delivery_service_id,
            item_id_1,
            item_id_2,
            units_ttl,
            is_parcel,
            is_largeletter,
            sum(_count) _count
        from
            ext.sales_item_doubles
        group by
            order_date,
            delivery_service_id,
            item_id_1,
            item_id_2,
            units_ttl,
            is_parcel,
            is_largeletter
     ) d
join
    ext.Item i1
on
    (
        d.item_id_1 = i1.ID
    )
join
    ext.Item i2
on
    (
        d.item_id_2 = i2.ID
    )
join
    ext.delivery_service s
on
    (
        d.delivery_service_id = s.id
    )
join
    hs_consolidated.[Delivery Service] t
on
    (
        s.company_id = t.company_id
    and s.code = t.Code
    )