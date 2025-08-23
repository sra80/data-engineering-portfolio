
CREATE view [forecast_feed].[open_transfers]

as

select
    row_number() over (order by d.key_date_shipment) primary_key,
    d.order_no_,
    d.key_location_from,
    d.key_location_to,
    key_item,
    key_date_shipment,
    CompanyX_ref,
    qty_shipped,
    qty_to_receive
from
    (
        select
            concat(th.[No_],'_',tl.[Line No_]) order_no_,
            th.[Transfer-from Code] key_location_from,
            th.[Transfer-to Code] key_location_to,
            i.ID key_item,
            convert(nvarchar,(select max(x.d) from (values(tl.[Receipt Date]),(getutcdate())) as x(d)),103) key_date_shipment,
            /*nb discussed with Bartek, the idea to set the date to tomorrow when it fell into the past, it will need cleaning up in NAV, this prevents outstanding shipments from falling into the past*/
            -- convert(nvarchar,tl.[Receipt Date],103) key_date_shipment,
            tl.[Anaplan Release ID] CompanyX_ref,
            tl.[Quantity] qty_shipped,
            -- case when sum(ts.[Quantity]) over (partition by th.[No_], tl.[Line No_] order by tl.[Receipt Date] rows between unbounded preceding and current row) - isnull(tr.[Quantity],0) < 0 then 0 else sum(ts.[Quantity]) over (partition by th.[No_], tl.[Line No_] order by tl.[Receipt Date] rows between unbounded preceding and current row) - isnull(tr.[Quantity],0) end qty_to_receive
            case when sum(tl.[Quantity]) over (partition by th.[No_], tl.[Line No_] order by tl.[Receipt Date] rows between unbounded preceding and current row) - isnull(tr.[Quantity],0) < 0 then 0 else sum(tl.[Quantity]) over (partition by th.[No_], tl.[Line No_] order by tl.[Receipt Date] rows between unbounded preceding and current row) - isnull(tr.[Quantity],0) end qty_to_receive
        from
            [dbo].[UK$Transfer Header] th
        join
            [dbo].[UK$Transfer Line] tl
        on
            (
                th.[No_] = tl.[Document No_]
            )
        join
            ext.Item i
        on
            (
                i.company_id = 1
            and tl.[Item No_] = i.No_
            )
        join
            [dbo].[UK$Item] ii
        on
            (
                tl.[Item No_] = ii.No_
            )
        -- left join
        --     (
        --         select 
        --             -- tsh.[Posting Date]
        --             tsh.[Transfer Order No_],
        --             tsl.[Line No_],
        --             tsl.[Quantity]
        --         from
        --             [dbo].[UK$Transfer Shipment Header] tsh
        --         join
        --             [dbo].[UK$Transfer Shipment Line] tsl
        --         on
        --             (
        --                 tsh.[No_] = tsl.[Document No_]
        --             )
        --         where
        --             [Quantity] > 0
        --     ) ts
        -- on
        --     (
        --         ts.[Transfer Order No_] = th.[No_]
        --     and ts.[Line No_] = tl.[Line No_]
        --     )
        left join
            (
                select 
                    trh.[Transfer Order No_],
                    -- trl.[Receipt Date],
                    -- ,trh.[Posting Date] 
                    trl.[Line No_],
                    trl.[Quantity]
                from
                    [dbo].[UK$Transfer Receipt Header] trh
                join
                    [dbo].[UK$Transfer Receipt Line] trl
                on
                    (
                        trh.[No_] = trl.[Document No_]
                    )
                where
                    [Quantity] > 0
            ) tr
        on
            (
                tr.[Transfer Order No_] = th.[No_]
            and tr.[Line No_] = tl.[Line No_]
            )
        where
            (
                -- tl.[Qty_ Shipped (Base)] > tl.[Quantity Received]
                tl.[In-Transit Code] = 'IN TRANSIT'
            and tl.[Quantity] > tl.[Quantity Received]
            and i.ID in (select key_item from forecast_feed.item)
            )

        union all

        select
            concat(ph.[No_],'_',pl.[Line No_]) order_no_,
            'WASDSP' key_location_from,
            pl.[Location Code] key_location_to,
            ioa.item_ID_overide key_item,
            -- convert(nvarchar,ph.[Posting Date],103) key_date_shipment,
            -- convert(nvarchar,pl.[Expected Receipt Date],103) key_date_shipment,
            convert(nvarchar,(select max(x.d) from (values(pl.[Expected Receipt Date]),(getutcdate())) as x(d)),103) key_date_shipment,
            pl.[Anaplan Release ID] CompanyX_ref,
            pl.[Quantity] qty_shipped,
            pl.[Outstanding Quantity] qty_to_receive
        from
            [hs_consolidated].[Purchase Header] ph
        join
            [hs_consolidated].[Purchase Line] pl
        on
            (
                ph.company_id = pl.company_id
            and ph.[No_] = pl.[Document No_]
            )
        join
            [hs_consolidated].[Vendor] v
        on
            (
                ph.company_id = v.company_id
            and ph.[Buy-from Vendor No_] = v.[No_]
            )
        join
            [ext].[Item] ei
        on
            (
                pl.company_id = ei.company_id
            and pl.[No_] = ei.[No_]
            )
        join
            forecast_feed.item_overide_aggregate ioa
        on
            (
                ei.ID = ioa.item_ID
            )
        join
            forecast_feed.location_overide_aggregate loa
        on
            (
                pl.company_id = loa.company_id
            and pl.[Location Code] = loa.location_code
            )
        join
            [dbo].[UK$Item] i
        on
            (
                pl.No_ = i.No_
            )
        where
            (
                ph.[Status] in (1,2)
            and ph.[Status 2] < 5
            and v.[IC Partner Code] = 'HS SELL'
            and pl.[Expected Receipt Date] > dateadd(day,-60,getutcdate())
            and pl.[Type] = 2
            and pl.[Outstanding Quantity] > 0
            and ioa.item_ID_overide in (select key_item from forecast_feed.item)
            )
            
    ) d
GO
