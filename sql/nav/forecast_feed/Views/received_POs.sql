
CREATE view [forecast_feed].[received_POs]

as

select
	row_number() over(order by ei.[ID]) [primary_key],
	ile.[Source No_] [vendor_no],
	'Received' [status],
    'Completed' [status_2],
    r.[order_no_],
	r.[prod_order_no_],
	r.[blanket_order_no_],
	ei.[ID] [item_id],
	ile.[Location Code] [location_code],
    convert(nvarchar,ile.[Posting Date],103) receipt_date,
    r.CompanyX_ref,
	ile.Quantity [qty]
from
    [dbo].[UK$Item Ledger Entry] ile
join
	[dbo].[UK$Vendor] v
on
	(
	ile.[Source No_] = v.[No_]
	)
join
	[ext].[Item] ei
on
	(
        ei.company_id = 1
    and ile.[Item No_] = ei.[No_]
	)
join
    [dbo].[UK$Item] i
on
    (
        ile.[Item No_] = i.[No_]
    )
left join
	[ext].[Location] x
on
	(
        x.company_id = 1
    and x.[location_code] = ile.[Location Code]
	)
cross apply
    [forecast_feed].[fn_received_POs_ref](1,ile.[Entry Type], ile.[Document No_], ile.[Item No_]) r
where
	(
        ile.[Entry Type] in (0,6)
    and ile.[Posting Date] >= db_sys.foweek(getutcdate(),-6)
	and ei.[ID] in (select key_item from forecast_feed.item)
    and v.[Type of Supply Code] = 'PROCUREMNT'
	)
GO
