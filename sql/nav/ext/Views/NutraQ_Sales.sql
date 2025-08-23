SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create or alter view [ext].[NutraQ_Sales]

as

select
    concat('Week ',datepart(wk,oq.[Order Date])) [Relative Week],
    db_sys.fn_eoweek(oq.[Order Date]) [W/C Date],
    format(sum(oq.[OrderCount]),'###,###,##0') [Sales Orders],
    format(sum(oq.[OrderUnits]),'###,###,##0') [Sales Units],
    format(sum(isnull(y.[Picked Quantity]/nullif(oq.[OrderUnits],0),0)),'###,###,##0') [Fulfilled Orders],
    format(sum(y.[Picked Quantity]),'###,###,##0') [Fulfilled Units]
from
    [ext].[OrderQueues] oq
join
    [dbo].[UK$Item] i
on
    (
        i.[No_] = oq.[Item No]
    )
left join
    (       
    select 
         wl.[Source No_]
        ,wl.[Registered DateTime]
        ,sum(wl.[Quantity]) [Picked Quantity] 
    from
        [ext].[Registered_Pick_Line] wl
    where
      (
          wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
      and wl.[company_id] = 1
      )
    group by
         wl.[Source No_]
        ,wl.[Registered DateTime]
    ) y
on
    (
        oq.[company_id] = 1
    and oq.[Order No] = y.[Source No_]
    and db_sys.fn_eoweek(oq.[Picked Date]) = db_sys.fn_eoweek(y.[Registered DateTime])
    )
where   
    (
        i.[Global Dimension 2 Code] = '110'
    and oq.[Order Date] >= dateadd(wk, -1, dateadd(day, 1-datepart(weekday, getutcdate()), datediff(dd, 0, getutcdate()))) 
    and oq.[Order Date] <= dateadd(wk, 0, dateadd(day, 0-datepart(weekday, getutcdate()), datediff(dd, 0, getutcdate()))) 
    )
group by
    db_sys.fn_eoweek(oq.[Order Date]),
    datepart(wk,oq.[Order Date])
GO


