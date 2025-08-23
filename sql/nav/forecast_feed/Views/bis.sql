create or alter view forecast_feed.bis

as

select
    concat(x.key_date,x.key_demand_channel,x.key_customer,x.key_sales_channel,x.key_location,x.key_item) primary_key,
    x.key_date,
    x.key_demand_channel,
    x.key_customer,
    x.key_sales_channel,
    x.key_location,
    x.key_item,
    sum(1) units
from
    (
        select
            datepart(year,oos.forecast_close_date) * 100 + datepart(week,oos.forecast_close_date) key_date,
            isnull((select p.Group_ID from tradeit.channel c join ext.Platform p on c.platform_id = p.ID where c.id = be.channel_id),1) key_demand_channel,
            -1000 key_customer,
            'D2C' key_sales_channel,
            48 key_location,
            be.item_id key_item
        from
            tradeit.bis_emaillist be
        cross apply
            (
                select top 1
                    op.forecast_close_date
                from
                    stock.oos_plr op
                where
                    (
                        op.row_version = (select row_version from stock.forecast_subscriptions_version where is_current = 1)
                    and op.rv_sub = 0
                    and op.location_id = 48
                    and op.is_oos = 1
                    and be.item_id = op.item_id
                    and be.webTS >= op.forecast_open_date
                    and be.webTS <= isnull(op.forecast_close_date,datefromparts(2099,12,31))
                    )
                order by
                    op.forecast_close_date
            ) oos

        union all

        select
            datepart(year,oos.forecast_close_date) * 100 + datepart(week,oos.forecast_close_date) key_date,
            0 key_demand_channel,
            -1000 key_customer,
            'D2C' key_sales_channel,
            48 key_location,
            ic.item_id key_item
        from
            hs_consolidated.[Interaction Log Entry] le
        cross apply
            (
                select
                    ic.item_id
                from
                    ext.Item_Channel ic
                where
                    (
                        ic.item_id = ext.fn_Item(company_id,le.[Item No_])
                    and ic.channel_id in (select ID from ext.Channel where Channel_Code = 'PHONE')
                    and ic.is_current = 1
                    and ic.tsOff <= getutcdate()
                    )
            ) ic
        cross apply
            (
                select top 1
                    op.forecast_close_date
                from
                    stock.oos_plr op
                where
                    (
                        op.row_version = (select max(row_version) from stock.forecast_subscriptions_version where is_current = 1)
                    and op.rv_sub = 0
                    and op.is_oos = 1
                    and op.is_batch = 1
                    and op.item_id = ic.item_id
                    and location_id in (select ID from ext.Location l where l.company_id = le.company_id and l.default_loc = 1)
                    and le.[Created DateTime] <= op.forecast_close_date
                    )
                order by
                    op.forecast_close_date
            ) oos
        where
            (
                le.[Interaction Group Code] = 'CUSTSERV'
            and le.[Interaction Template Code] = 'ADMIN'
            and le.[Category Code] = 'CUSTSERV'
            and le.[Reason Code] in ('OOSCB','OOSLETTER')
            and le.[Closed] = 0
            )
    ) x
group by
    x.key_date,
    x.key_demand_channel,
    x.key_customer,
    x.key_sales_channel,
    x.key_location,
    x.key_item