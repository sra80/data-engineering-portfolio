SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create or alter procedure [ext].[sp_TradeItUK_Stock_AvailabilityDate]

as

set nocount on

delete from [ext].[TradeItUK_Stock_AvailabilityDate] where [InsertedUTC] < dateadd(day,-30, getdate())

insert into [ext].[TradeItUK_Stock_AvailabilityDate] ([ProductCode],[WarehouseCode],[AvailabilityDate],[InsertedUTC])
select
    ob.[ProductCode],
    'WASDSP' [WarehouseCode],
    -- dateadd(day,5,db_sys.foweek(po.[erd],case when ob.[Range Code] = 'ELITE' then 3 when po.distribution_loc = 1 then 0 else 1 end)) [po.erd],
    -- qa.erd,
    -- non_dist.erd,
    (select min(d.x) from (values(dateadd(day,5,db_sys.foweek(po.[erd],case when ob.[Range Code] = 'ELITE' then 3 when po.distribution_loc = 1 then 0 else 1 end))),(qa.erd),(non_dist.erd)) as d(x)) [AvailabilityDate],
    getutcdate() [InsertedUTC]
from
    (
        select 
            os.[Item No_] [ProductCode],
            i.[Range Code]
        from 
            [dbo].[UK$Outbound Stock] os
        join
            [dbo].[UK$Item] i
        on
            (
                i.[No_] = os.[Item No_]
            )
        where 
             os.[Available Quantity] = 0
    ) ob
outer apply
    (
        select top 1
             pl.[Expected Receipt Date] erd
            ,l0.distribution_loc
        from
            [dbo].[UK$Purchase Line] pl
        join
            [dbo].[UK$Purchase Header] ph
        on
            (
                ph.[Document Type] = pl.[Document Type]
            and ph.[No_] = pl.[Document No_]
            )
        join
            ext.Location l0
        on
            (
                l0.company_id = 1
            and pl.[Location Code] = l0.location_code
            )
        where
               (
                    ph.[Document Type] = 1
                and ph.[Status] in (1,2)
                and ph.[Status 2] < 5
                and ob.[ProductCode] = pl.[No_] 
                and pl.[Type] = 2
                and pl.[Outstanding Quantity] > 0
                and pl.[Expected Receipt Date] >=  db_sys.foweek(getdate(),0)
               )
        order by
            pl.[Expected Receipt Date]
    ) po
outer apply
    (
        select 
            [Item No_],
            (select top 1 qa.expected_release from ext.Item_Batch_Info ibi cross apply [stock].[fn_qa_status] (ibi.[ID]) qa where company_id = 1 and sku = ob.[ProductCode] order by 1) erd
        from
            [dbo].[UK$Outbound Stock] os
        where
            os.[Qty_ in QC] > 0
        and (select top 1 ldd from ext.Item_Batch_Info ibi cross apply [stock].[fn_qa_status] (ibi.[ID]) qa where company_id = 1 and sku = ob.[ProductCode] order by 1) >= convert(date, getdate())
    ) qa
outer apply
    (
        select 
             [Item No_]
            ,[Location Code]
            ,dateadd(day,5,db_sys.foweek(getdate(),case when ob.[Range Code] = 'ELITE' then 3 else 1 end))  erd
            ,sum([Quantity]) [Qty]
        from
            [dbo].[UK$Item Ledger Entry] ile
        join
            ext.Location l0
        on
            (
                l0.company_id = 1
            and ile.[Location Code] = l0.location_code
            )
        where
            (    
                ob.[ProductCode] = ile.[Item No_]
            and l0.distribution_loc = 0
            and l0.[holding_loc] = 1
            and l0.[country] = 'GB'
            )
        group by
             [Item No_]
            ,[Location Code]
        having
            sum([Quantity]) > 0 
    ) non_dist
where
    (
        coalesce(po.erd,qa.erd,non_dist.erd) is not null
    )
GO