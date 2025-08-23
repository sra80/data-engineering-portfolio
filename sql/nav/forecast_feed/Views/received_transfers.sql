CREATE   view [forecast_feed].[received_transfers]

as

select
    row_number() over (order by key_receipt_date) primary_key,
    order_no_,
    key_location_from,
    key_location_to,
    key_item,
    key_receipt_date,
    CompanyX_ref,
    qty_received
from
    (
        select 
            concat(ile.[Order No_],'_',ile.[Order Line No_]) order_no_,
            trh.[Transfer-from Code] key_location_from,
            trh.[Transfer-to Code] key_location_to,
            ei.ID key_item,
            convert(nvarchar,ile.[Posting Date],103) key_receipt_date,
            trl.[Anaplan Release ID] CompanyX_ref,
            ile.Quantity qty_received
        from
            [UK$Item Ledger Entry] ile
        join
            [dbo].[UK$Transfer Receipt Header] trh
        on
            (
                ile.[Document No_] = trh.[No_]
            )
        join
            [dbo].[UK$Transfer Receipt Line] trl
        on
            (
                ile.[Document No_] = trl.[Document No_]
            and ile.[Document Line No_] = trl.[Line No_]
            )
        join
            [ext].[Item] ei
        on
            (
                ei.company_id = 1
            and ile.[Item No_] = ei.[No_]
            )
        where
            (
                ile.[Entry Type] = 4
            and ile.[Positive] = 1
            and ile.[Posting Date] >= db_sys.foweek(getutcdate(),-6)
            and ei.[ID] in (select key_item from forecast_feed.item)
            )

        union all

        select
            r.[order_no_],
            'WASDSP' key_location_from,
            ile.[Location Code] key_location_to,
            ioa.item_ID_overide [key_item],
            convert(nvarchar,ile.[Posting Date],103) key_receipt_date,
            r.CompanyX_ref,
            ile.Quantity qty_received
        from
            [hs_consolidated].[Item Ledger Entry] ile

        join
            [hs_consolidated].[Vendor] v
        on
            (
                ile.company_id = v.company_id
            and ile.[Source No_] = v.[No_]
            )
        join
            [ext].[Item] ei
        on
            (
                ei.company_id = 1
            and ile.[Item No_] = ei.[No_]
            )
        join
            forecast_feed.item_overide_aggregate ioa
        on
            (
                ei.ID = ioa.item_ID
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
        outer apply
            [forecast_feed].[fn_received_POs_ref](ile.company_id,ile.[Entry Type], ile.[Document No_], ile.[Item No_]) r
        where
            (
                ile.[Entry Type] in (0,6)
            and ile.company_id > 1
            and ile.Positive = 1
            and ile.[Posting Date] >= db_sys.foweek(getutcdate(),-6)
            and ioa.item_ID_overide in (select key_item from forecast_feed.item)
            and v.[IC Partner Code] = 'HS SELL'
            )

    ) x
GO
