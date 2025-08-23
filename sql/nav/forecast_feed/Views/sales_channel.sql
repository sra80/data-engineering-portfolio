
CREATE view [forecast_feed].[sales_channel]

as

select 
    dv.Code key_sales_channel,
    dv.[Name] sales_channel 
from
    (
        select
            [Dimension Code],
            Code,
            min(company_id) company_id
        from
            hs_consolidated.[Dimension Value]
        where
            [Dimension Code] = 'SALE.CHANNEL'
        group by
            [Dimension Code],
            Code
    ) agg
join
    hs_consolidated.[Dimension Value] dv
on
    (
        agg.company_id = dv.company_id
    and agg.[Dimension Code] = dv.[Dimension Code]
    and agg.Code = dv.Code
    )
where
    (
        dv.Code not in ('IC','INT')
    )
GO
