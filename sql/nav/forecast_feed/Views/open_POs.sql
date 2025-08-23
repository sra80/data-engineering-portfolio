create or alter view [forecast_feed].[open_POs]

as

select
	row_number() over(order by ei.[ID]) [primary_key],
	ph.[Buy-from Vendor No_] [vendor_no],
	db_sys.fn_Lookup('Purchase Header','Status',ph.[Status]) [status],
	db_sys.fn_Lookup('Purchase Header','Status',ph.[Status 2]) [status_2],
	concat(ph.[No_],'_',pl.[Line No_]) [order_no_],
	pl.[Prod_ Order No_] [prod_order_no_],
	pl.[Blanket Order No_] [blanket_order_no_],
	ei.[ID] [item_id],
	x.[location_code],
    convert(nvarchar,(select max(x.d) from (values(pl.[Expected Receipt Date]),(getutcdate())) as x(d)),103) expected_receipt_date,
    pl.[Anaplan Release ID] CompanyX_ref,
	pl.[Outstanding Quantity] [qty]
from
	[dbo].[UK$Purchase Header] ph
join
	[dbo].[UK$Purchase Line] pl
on
	(
        ph.[Document Type] = pl.[Document Type]
    and ph.[No_] = pl.[Document No_]
	)
join
	[dbo].[UK$Vendor] v
on
	(
	ph.[Buy-from Vendor No_] = v.[No_]
	)
join
	[ext].[Item] ei
on
	(
        ei.company_id = 1
    and pl.[No_] = ei.[No_]
	)
join
    [dbo].[UK$Item] i
on
    (
        pl.[No_] = i.[No_]
    )
left join
	[ext].[Location] x
on
	(
        x.company_id = 1
    and x.[location_code] = pl.[Location Code]
	)
where
	(
        ph.[Document Type] = 1
    and ph.[Status] between 1 and 3
	and ph.[Status 2] < 5
	and v.[Type of Supply Code] = 'PROCUREMNT'
	and pl.[Type] = 2
	and pl.[Outstanding Quantity] > 0
	and ei.[ID] in (select key_item from forecast_feed.item)
	)
GO
