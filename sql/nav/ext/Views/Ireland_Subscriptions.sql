SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE or ALTER view [ext].[Ireland_Subscriptions]


as


select
	 sum(w.[Picked Quantity]) [Units]
	,round(sum(isnull(w.[Picked Quantity]/nullif(w.[OrderUnits],0),0)),0) [Orders]
from
	(
        select
             y.[keyPickDate]
			,z.[company_id]
            ,z.[Location Code]
            ,z.[keyChannelCode]
            ,z.[keyOrderNo]
            ,z.[keySKU]
            ,y.[Picked Quantity]
			,y1.[OrderUnits]
        from
            (
                select 
                     wsl.[No_] [Whse Shipment No]
					,wsh.[company_id]
                    ,wsl.[Location Code]
                    ,wsl.[Channel Code] [keyChannelCode]
                    ,wsl.[Source No_] [keyOrderNo]
                    ,wsl.[Item No_] [keySKU]
                from
                    [hs_consolidated].[Warehouse Shipment Line] wsl 
                join
					[hs_consolidated].[Warehouse Shipment Header] wsh
				on
					(
						 wsh.[company_id] = wsl.[company_id]
					 and wsh.[No_] = wsl.[No_]
                    )

                union 

                select  
                     pwsl.[Whse_ Shipment No_] [Whse Shipment No]
					,pwsh.[company_id]
                    ,pwsl.[Location Code]
                    ,pwsl.[Channel Code] [keyChannelCode]
                    ,pwsl.[Source No_] [keyOrderNo]
                    ,pwsl.[Item No_] [keySKU]
                from
                    [ext].[Posted_Whse_Line] pwsl
				join
					[ext].[Posted_Whse_Header] pwsh 
				on
					(
						pwsl.[company_id] = pwsh.[company_id]
					and pwsl.[No_] = pwsh.[No_]
					)
            ) z
        join
            (
                select 
                     wh.[Registering Date] [keyPickDate]
					,wh.[company_id]
                    ,wl.[Whse_ Document No_] 
                    ,wl.[Source No_] 
                    ,wl.[Item No_] 
                    ,sum(wl.[Quantity]) [Picked Quantity] 
                from
                    [ext].[Registered_Pick_Line] wl
                join
                    [ext].[Registered_Pick_Header] wh
                on
                    (
						 wh.[company_id] = wl.[company_id]
					 and wh.[No_] = wl.[No_]
					 )
                where
                    wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
                group by
                     wh.[Registering Date] 
					,wh.[company_id]
                    ,wl.[Whse_ Document No_]
                    ,wl.[Source No_]
                    ,wl.[Item No_]
            ) y
        on
			(
				z.[company_id] = y.[company_id]
			and z.[Whse Shipment No] = y.[Whse_ Document No_]
			and z.[keyOrderNo] = y.[Source No_]
			and z.[keySKU] = y.[Item No_]
			)
		left join
			(
				select
						 [Order No]
						,[company_id]
						,sum([OrderUnits]) [OrderUnits]
					from
						[ext].[OrderQueues]
					group by
						 [Order No]
						,[company_id]
						) y1
					on
						(
							y1.[company_id] = y.[company_id]
						and y1.[Order No] = y.[Source No_]
						)

	) w
join
	[logistics].[Channel] ch 
on
    (
        [logistics].[fn_order_channel](w.[company_id],w.[keyChannelCode]) = ch.[keyChannel]
    )
join
	[logistics].[Country] c
on
	(
		isnull(nullif([logistics].[fn_order_country] (w.[keyOrderNo],w.[company_id]),''),-1) = c.keyCountry
	)
where
    w.[company_id] = 6
and w.[Location Code] = 'ONESTOP'
and w.[keyPickDate] >= datefromparts(year(getdate()),month(getdate())-1,1)
and w.[keyPickDate] <= eomonth(dateadd(month,-1,getdate()))
and c.keyCountryCode = 'IE'
and ch.ord_chann_code = '6REPEAT'


GO
