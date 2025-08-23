CREATE view [forecast_feed].[ringFenced]

as

select
    concat(rf.key_date,rf.key_demand_channel,rf.key_customer,rf.key_sales_channel,rf.key_location,rf.key_item) primary_key,
    rf.key_date,
    rf.key_demand_channel,
    rf.key_customer,
    rf.key_sales_channel,
    rf.key_location,
    rf.key_item,
    rf.units
from
    (
        select
            x.key_date,
            x.key_demand_channel,
            x.key_customer,
            x.key_sales_channel,
            x.key_location,
            x.key_item,
            ceiling(sum(x.Quantity)) units
        from
            (
                select
                    datepart(year,rfe.[Expected Delivery Date])*100 + datepart(week,rfe.[Expected Delivery Date]) key_date,
                    -- ext.fn_Platform(rfe.company_id,'REPEAT','SO-123456','NAV',0) key_demand_channel,
                    ext.fn_Platform_Grouping(rfe.company_id,'REPEAT','SO-123456','NAV',0) key_demand_channel,
                    -- (select -min(ID)-1 ID from ext.Customer_Type ct where nav_code = 'DIRECT') key_customer,
                    -1000 key_customer,
                    'D2C' key_sales_channel,
                    loc.location_ID_overide key_location,
                    i.ID key_item,
                    rfe.Quantity
                from
                    hs_consolidated.[Ring Fencing Entry] rfe
                join
                    forecast_feed.location_overide_aggregate loc
                on
                    (
                        rfe.company_id = loc.company_id
                    and rfe.[Location Code] = loc.location_code
                    )
                join
                    [hs_consolidated].[Item] ii
                on
                    (
                        rfe.company_id = ii.company_id
                    and rfe.[Item No_] = ii.No_
                    )
                cross apply
                    (
                        select
                            min(ID) ID
                        from
                            ext.Item i
                        where
                            (
                                rfe.[Item No_] = i.No_
                            )
                    ) i
                    --     cross apply
                    -- (
                    --     select
                    --         forecast_feed.fn_location_overide(loc.location_code) location_code,
                    --         min(ID) ID
                    --     from
                    --         ext.Location loc
                    --     where
                    --         (  
                    --             rfe.[Location Code] = forecast_feed.fn_location_overide(loc.location_code)
                    --         )
                    --     group by
                    --         forecast_feed.fn_location_overide(loc.location_code)
                    -- ) loc
                where
                    (
                        rfe.[Expected Delivery Date] > datefromparts(1753,1,1)
                    and i.ID in (select key_item from forecast_feed.item)
                    )
            ) x
        group by
            x.key_date,
            x.key_demand_channel,
            x.key_customer,
            x.key_sales_channel,
            x.key_location,
            x.key_item
    ) rf
GO
