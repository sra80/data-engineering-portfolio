create or alter view [stock].[StockManagement_onOrder]

as

select 
	-1 model_partition,
	l.company_id,
    cr.ID country_id,
	convert(date,sysdatetime()) key_posting_date,
    211 opt_key,
	0 is_amazon,
    1002 key_DocumentType,
    (select ID from ext.Location loc where loc.company_id = l.company_id and loc.location_code = l.[Location Code]) key_location,
    i.ID key_sku,
    ext.fn_Item_Batch_Info(l.company_id,l.[No_],'dummy','On Order') key_batch,
	-l.[Outstanding Quantity] Quantity,
    c.cost_actual [Cost Actual],
    0 [Cost Expected],
    null [Cost Posted to G_L],
    ext.fn_Convert_Currency_GBP(l.Amount/case when ceiling(h.[Currency Factor]) > 0 then h.[Currency Factor] else 1 end,l.company_id,sysdatetime()) [Sales Amount (Actual)],
    null [Discount Amount]
from 
	hs_consolidated.[Sales Line] l 
join 
	hs_consolidated.[Sales Header] h 
on 
	(
        h.company_id = l.company_id
    and h.No_ = l.[Document No_] 
	and l.[Document Type] = h.[Document Type]
	) 
join
    ext.Item i
on
    (
        l.company_id = i.company_id
    and l.No_ = i.No_
    )
join
    ext.Sales_Header e
on
    (
        h.company_id = e.company_id
    and h.No_ = e.No_
    and h.[Document Type] = e.[Document Type]
    )
left join
    db_sys.outcode o
on
    (
        nullif(e.outcode_id,-1) = o.id
    )
left join
    ext.Country_Region cr
on
    (
        h.company_id = cr.company_id
    and isnull(o.country,h.[Ship-to Country_Region Code]) = cr.country_code
    )
outer apply
    (
        select top 1
            iua.cost_actual
        from
            ext.Item_UnitCost iua
        where
            (
                iua.item_ID = i.ID
            )
        order by
            iua.row_version desc
    ) c
where 
	(
		h.[Sales Order Status] = 1 
	and len(l.[Location Code]) > 0
	and abs(l.[Outstanding Quantity]) > 0
	)
GO
