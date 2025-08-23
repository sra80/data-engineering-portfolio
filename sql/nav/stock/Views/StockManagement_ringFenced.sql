create or alter view [stock].[StockManagement_ringFenced]

as

select
	-2 model_partition,
	r.company_id,
    o.country_id,
	convert(date,sysdatetime()) key_posting_date,
    211 opt_key,
	0 is_amazon,
    1003 key_DocumentType,
	(select ID from ext.Location loc where loc.company_id = r.company_id and loc.location_code = r.[Location Code]) key_location,
    i.ID key_sku,
    ext.fn_Item_Batch_Info(r.company_id,r.[Item No_],'dummy','Ring Fenced') key_batch,
	-r.Quantity Quantity,
    c.cost_actual [Cost Actual],
    0 [Cost Expected],
    null [Cost Posted to G_L],
    null [Sales Amount (Actual)],
    null [Discount Amount]
from
	hs_consolidated.[Ring Fencing Entry] r
join
    hs_consolidated.[Subscriptions Header] s
on
    (
        r.company_id = s.company_id
    and r.[Subscription No_] = s.No_
    )
join
    ext.Item i
on
    (
        r.company_id = i.company_id
    and r.[Item No_] = i.No_
    )
cross apply
    db_sys.fn_outcode_countrycode(r.company_id,s.[Ship-to Post Code],s.[Ship-to Country_Region Code]) o
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
		len(r.[Location Code]) > 0
	and abs(r.Quantity) > 0
	)
GO
