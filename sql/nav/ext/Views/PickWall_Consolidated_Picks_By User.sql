SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create or alter view [ext].[PickWall_Consolidated_Picks_By User]

as

with oq as
(
    select
        [Order No], 
        sum([OrderUnits]) [OrderUnits]
    from
        [ext].[OrderQueues]
    group by
        [Order No]
)


select
    rwah.[Registering Date],
    parsename(replace(rwah.[Assigned User ID], '\', '.'), 1) [Assigned User], 
    'Pick Wall Consolidated' [Shipment Type],
    sum(rwal.[Quantity]) [Picked Units],
    sum(coalesce(rwal.[Quantity] * 1.0 / nullif(oq.[OrderUnits], 0), 0)) [Picked Orders]
from
    [dbo].[UK$Registered Whse_ Activity Hdr_] rwah
join
    [dbo].[UK$Registered Whse_ Activity Line] rwal
on
    (
        rwah.[No_] = rwal.[No_]
    and rwal.[Action Type] = 2
    )
join
    oq
on
    (
        oq.[Order No] = rwal.[Source No_]
    )
where
    (
        rwah.[Whse_ Shipment Type] = 4  -- Pick Wall Consolidated
    and rwah.[Assigned User ID] IN ('CompanyX\PACKSTATION1', 'CompanyX\PACKSTATION2', 'CompanyX\PACKSTATION3', 'CompanyX\PACKSTATION4')
    and rwah.[Registering Date] > convert(date,dateadd(month,-24, getutcdate()))
    )
group by
    rwah.[Registering Date],
    rwah.[Assigned User ID]
GO