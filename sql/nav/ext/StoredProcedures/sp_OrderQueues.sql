SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--01 change to select only the first instance of a duplicate order and therefore prevent PK violation	
--02 added Whse Line No as a column and PK to prevent PK violation due to single order lines being released into whse shipments as multiple lines



create or alter procedure [ext].[sp_OrderQueues]



as



set nocount on



exec db_sys.sp_auditLog_procedure @procedureName='[ext].[sp_warehouse]', @parent_procedureName='[ext].[sp_OrderQueues]'



delete from [ext].[OrderQueues] where [Processing Queue] in ('Inbound Sales Header','Sales Header')



insert into [ext].[OrderQueues] ([company_id],[processing_queue],[Processing Queue],[Order Date],[Origin Date],[Inbound Date],[Order Created Date],[Released To Whse Date],[Whse No],[Whse Line No],[Picked Date],[Pick No],[Pick Line No],[Integration],[Inbound Status],[Inbound Error],[Country Code],[Channel Code],[Dispatch Location], [courier_delivery], [Order Status],[Warehouse Status],[On Hold Code],[On Hold Reason],[Order No],[Order Line No],[Item No],[picking_required],[OrderCount],[OrderUnits],[Qty Picked By Pick Date],[Qty Picked By Order Line],[OrderAmount],[Qty Shipped],[Qty Invoiced],[Document Type],[Doc_ No_ Occurrence],[Version No_],[rn])

select 

	 ish.[company_id]

	,0 [processing_queue]

	,'Inbound Sales Header' [Processing Queue]

	,ish.[Order Date]

	,convert(datetime,switchoffset(ish.[Origin Datetime],datepart(tzoffset,ish.[Origin Datetime] at time zone 'GMT Standard Time'))) [Origin Date] 

	,convert(datetime,switchoffset(ish.[Created Date Time],datepart(tzoffset,ish.[Created Date Time] at time zone 'GMT Standard Time'))) [Inbound Date]

	,null [Order Created Date]

	,null [Released To Whse Date]

	,'WAS-00000000' [Whse No]

    ,0 [Whse Line No] -- 02

	,null [Picked Date]

	,'WRP-00000000' [Pick No]

	,0 [Pick Line No]

	,ish.[Integration Code] [Integration]

	,case

		when ish.[Status] = 0 then 'Awaiting Processing'

		when ish.[Status] = 1 then 'Processed'

		when ish.[Status] = 2 then 'Errored'

		when ish.[Status] = 3 then 'Cancelled'

		end [Inbound Status]

	,el.[Inbound Error]

	,ish.[Shipment Country Code] [Country Code]

	,null [Channel Code]

	,isla.[Dispatch Location]

	--,[ext].[fn_delivery_service] (ish.[Document No_]) [Delivery Service]

	,[logistics].[fn_courier_delivery] (ish.[Document No_],ish.[company_id]) [courier_delivery]

	,'Inbound Queue' [Order Status]

	,'Inbound Queue' [Warehouse Status]

	,0 [On Hold Code]

	,null [On Hold Reason]

	,isnull(nullif(ish.[Document No_],''),ish.[Your Reference]) [Order No]

	,isla.[Line No_] [Order Line No]

	,isla.[Item No]

	,case

		when ish.[Integration Code] in ('AMAZONFBM-UK','EBAY-IE','EBAY-UK','SITECORE9','TRADEIT-IE','TRADEIT-UK') then 1 else 0 

		end [picking_required]

	,case

		when isla.[Line No_] = min(isla.[Line No_]) over (partition by isla.[Header ID]) then 1

		else 0

		end [OrderCount]

	,isla.[Units] [OrderUnits]

	,NULL [Qty Picked By Pick Date]

	,NULL [Qty Picked By Order Line]

	,0 [OrderAmount]

	,0 [Qty Shipped]

	,0 [Qty Invoiced]

	,1 [Document Type]

	,1 [Doc_ No_ Occurrence]

	,1 [Version No_]

	,1 rn

from

	(

		select --distinct M01

			  min([ID]) [ID] --[ID] M01

			,[company_id]

			,[Order Date]

			,[Origin Datetime]

			,min([Created Date Time]) [Created Date Time] --[Created Date Time] M01

			,[Integration Code]

			,[Status]

			,[Shipment Country Code]

			,[Document No_]

			,[Your Reference]

		from

			[hs_consolidated].[Inbound Sales Header] ish 

		where

			ish.[Status] in (0,2)

		--M01
		group by

			[company_id]

			,[Order Date]

			,[Origin Datetime]

			,[Integration Code]

			,[Status]

			,[Shipment Country Code]

			,[Document No_]

			,[Your Reference]	
	)

	ish

join

	(

	select

		 isl.[Location Code]  [Dispatch Location]

		,isl.[NAV Document No_]

		,isl.[Header ID]

		,isl.[company_id]

		,isl.[No_] [Item No]

		,isl.[Line No_]

		,sum(isl.[Quantity]) [Units]

	from

		[hs_consolidated].[Inbound Sales Line] isl 

	where

		patindex('ZZ%',isl.[No_]) = 0

	group by

		 isl.[Location Code]

		,isl.[NAV Document No_]

		,isl.[Header ID]

		,isl.[company_id]

		,isl.[No_] 

		,isl.[Line No_]

	) isla

on

	(

			ish.[company_id] = isla.[company_id]

		and ish.[ID] = isla.[Header ID]

		and ish.[Order Date]  >= datefromparts(year(getdate())-2,1,1)

	)

left join

	[logistics].[ErrorLog] el

on

	(

		el.[Source Record ID] = ish.[ID]

	and el.[company_id] = ish.[company_id]

	)


insert into [ext].[OrderQueues] ([company_id],[processing_queue],[Processing Queue],[Order Date],[Origin Date],[Inbound Date],[Order Created Date],[Released To Whse Date],[Whse No],[Whse Line No],[Picked Date],[Pick No],[Pick Line No],[Integration],[Inbound Status],[Inbound Error],[Country Code],[Channel Code],[Dispatch Location],[courier_delivery], [Order Status],[Warehouse Status],[On Hold Code],[On Hold Reason],[Order No],[Order Line No],[Item No],[picking_required],[OrderCount],[OrderUnits],[Qty Picked By Pick Date],[Qty Picked By Order Line],[OrderAmount],[Qty Shipped],[Qty Invoiced],[Document Type],[Doc_ No_ Occurrence],[Version No_],[rn])

select 

	 sh.[company_id]

	,1 [processing_queue]

	,'Sales Header' [Processing Queue]

	,sh.[Order Date]

	,case

		when coalesce(convert(datetime,switchoffset(ish.[Origin Datetime],datepart(tzoffset,ish.[Origin Datetime] at time zone 'GMT Standard Time'))),convert(datetime,switchoffset(sh.[Origin Datetime],datepart(tzoffset,sh.[Origin Datetime] at time zone 'GMT Standard Time')))) = '17530101' then coalesce(convert(datetime,switchoffset(ish.[Created Date Time],datepart(tzoffset,ish.[Created Date Time] at time zone 'GMT Standard Time'))),convert(datetime, switchoffset(sh.[Created DateTime], datepart(tzoffset,sh.[Created DateTime] at time zone 'GMT Standard Time'))))

	 else coalesce(convert(datetime,switchoffset(ish.[Origin Datetime],datepart(tzoffset,ish.[Origin Datetime] at time zone 'GMT Standard Time'))),convert(datetime,switchoffset(sh.[Origin Datetime],datepart(tzoffset,sh.[Origin Datetime] at time zone 'GMT Standard Time'))))

	 end [Origin Date]

	,convert(datetime,switchoffset(ish.[Created Date Time],datepart(tzoffset,ish.[Created Date Time] at time zone 'GMT Standard Time'))) [Inbound Date]

	,convert(datetime, switchoffset(sh.[Created DateTime], datepart(tzoffset,sh.[Created DateTime] at time zone 'GMT Standard Time'))) [Order Created Date]

	,convert(datetime, switchoffset(ws.[Relased to Whse], datepart(tzoffset,ws.[Relased to Whse] at time zone 'GMT Standard Time'))) [Relased to Whse]

	,isnull(ws.[Whse No],'WAS-00000000') [Whse No]

    ,isnull(ws.[Whse Line No],0) [Whse Line No]

	,convert(datetime, switchoffset(rp1.[Pick DateTime], datepart(tzoffset,rp1.[Pick DateTime] at time zone 'GMT Standard Time'))) [Picked Date]

	,isnull(rp1.[No_],'WRP-00000000') [Pick No]

	,isnull(rp1.[Line No_],0) [Pick Line No]

	,sh.[Inbound Integration Code] [Integration]

	,case

		when ish.[Status] = 0 then 'Awaiting Processing'

		when ish.[Status] = 1 then 'Processed'

		when ish.[Status] = 2 then 'Errored'

		when ish.[Status] = 3 then 'Cancelled'

	 end [Inbound Status]

	,null [Inbound Error]

	,sh.[Ship-to Country_Region Code] [Country Code]

	,sh.[Channel Code]

	,sla.[Dispatch Location]

	--,[ext].[fn_delivery_service] (sh.[No_]) [Delivery Service]

	,[logistics].[fn_courier_delivery] (sh.[No_],sh.[company_id]) [courier_delivery]

	,case

		when sh.[Sales Order Status] = 0 then 'Open'

		when sh.[Sales Order Status] = 1 then 'Promised'

		when sh.[Sales Order Status] = 2 then 'Release Failed'

	 end [Order Status]

	,case

		when sh.[Status] = 0 then 'Open'

		when sh.[Status] = 1 then 'Released'

		when sh.[Status] = 2 then 'Pending Approval'

		when sh.[Status] = 3 then 'Pending Prepayment'

	 end [Warehouse Status]

	,case

		when sh.[On Hold] is null then 0

		else 1

	 end [On Hold Code]

	,sh.[On Hold] [On Hold Reason]

    ,sh.[No_] [Order No]

	,sla.[Line No_] [Order Line No]

	,sla.[Item No]

	,case

		when sla.[Dispatch Location] not in ('WASDSP','ONESTOP') or sla.[Units] = 0 or sla.[Units] = rp2.SOLinePickQty then 0 else 1 --01

	 end [picking_required]

	 ,case

		when sla.[Line No_] = min(sla.[Line No_]) over (partition by sla.[Document No_]) and row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1  then 1 --05

		else 0

	 end [OrderCount]

	 ,case

		when row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1 then sla.[Units]

	 else 0

	 end [OrderUnits]

	,rp1.PickDocQty [Qty Picked By Pick Date] --to group by pick date, i.e. one order line qty of 2 picked at different times HO-20274279; TURM5060 - joins will split that one order line into two because of 2 pick dates and show picked qty for each pick date

	,case

		when row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1 then rp2.SOLinePickQty

	 else 0

	 end [Qty Picked By Order Line] --to group by order line, i.e. order line qty of 2 picked at different times HO-20274279; TURM5060 - joins will split that one order line into two because of 2 pick dates and show total line qty in only first line

	,case

		when row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1 then round(sla.[Amount]/case when ceiling(sh.[Currency Factor]) > 0 then sh.[Currency Factor] else 1 end,2)

	 else 0

	 end [OrderAmount]

	,case

		when row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1 then sla.[Qty Shipped]

	 else 0

	 end [Qty Shipped]

	,case

		when row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1 then sla.[Qty Invoiced]

	 else 0

	 end [Qty Invoiced]

	,sh.[Document Type]

	,1 [Doc_ No_ Occurrence]

	,1 [Version No_]

	,row_number() over (partition by sla.[Document Type],sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) rn

from

	[ext].[Sales_Header] sh

outer apply

	(select top 1 [ID]

		,[company_id]

		,[Origin Datetime]

		,[Created Date Time]

		,[Status]

		,[Document No_]

	from

		[hs_consolidated].[Inbound Sales Header] ish

	where

		(

			sh.[company_id] = ish.[company_id]

		and	sh.[No_] = ish.[Document No_] 

		and ish.[Status] in (1)--,3)  --around 50ish orders cancelled that are actaully proceesed --currently excluded because of PK violation

		)

	)

	ish

join

	(

	select

		 sl.[Location Code]  [Dispatch Location]

		,sl.[Document No_]

		,sl.[Document Type]

		,sl.[company_id]

		,sl.[No_] [Item No]

		,sl.[Line No_]

		,sum(sl.[Quantity]) [Units]

		,sum(sl.[Quantity Shipped]) [Qty Shipped] 

		,sum(sl.[Quantity Invoiced]) [Qty Invoiced]

		,sum(sl.[Amount]) [Amount]

	from

		[ext].[Sales_Line] sl 

	where

		patindex('ZZ%',sl.[No_]) = 0

	group by

		 sl.[Location Code]  

		,sl.[Document No_]

		,sl.[Document Type]

		,sl.[company_id]

		,sl.[No_] 

		,sl.[Line No_]

	) sla

on 

	(

		sh.[company_id] = sla.[company_id]

	and sh.[No_] = sla.[Document No_] 

	and sh.[Document Type] = sla.[Document Type]

	)

left join

	(

		select    

			 isnull(wh.[Process End DateTime],isnull(nullif(wl.[Registered DateTime],'17530101'),wh.[Registering Date])) [Pick DateTime]

			,wl.[No_]

			,wl.[Line No_]

			,wl.[Source No_] orderNo

			,wl.[company_id]

			,wl.[Source Line No_]

			,wl.[Item No_] itemNo

			,wl.[Whse_ Document No_]

			,wl.[Whse_ Document Line No_]

			,sum(wl.[Quantity]) PickDocQty

		from

			[ext].[Registered_Pick_Line] wl 

		join

			[ext].[Registered_Pick_Header] wh

		on

			(

				wh.[company_id] = wl.[company_id]

			and	wh.[No_] = wl.[No_]

			)

		where

			wl.[Activity Type] = 2 --(2 = pick; 3 = movement)

		--and wl.[Action Type] = 2

		--and wl.[Source No_] = 'SO-07203882'

		group by

			 isnull(wh.[Process End DateTime],isnull(nullif(wl.[Registered DateTime],'17530101'),wh.[Registering Date])) 				

			,wl.[No_]

			,wl.[Line No_]

			,wl.[Source No_]

			,wl.[company_id]

			,wl.[Source Line No_]

			,wl.[Item No_]	

			,wl.[Whse_ Document No_]

			,wl.[Whse_ Document Line No_]

	) rp1

on 

	(

		rp1.[company_id] = sla.[company_id]

	and rp1.[orderNo] = sla.[Document No_]

	and rp1.itemNo = sla.[Item No]

	and rp1.[Source Line No_] = sla.[Line No_]

	)

left join

	(

		select    

			 wl.[Source No_] orderNo

			,wl.[company_id]

			,wl.[Source Line No_]

			,wl.[Item No_] itemNo

			,sum(wl.[Quantity]) SOLinePickQty

		from

			[ext].[Registered_Pick_Line] wl 

		join

			[ext].[Registered_Pick_Header] wh

		on 

			(

				wh.[company_id] = wl.[company_id]

			and	wh.[No_] = wl.[No_]

			)

		where

			wl.[Activity Type] = 2 --(2 = pick; 3 = movement)

		--and wl.[Action Type] = 2

		group by

			 wl.[Source No_]

			,wl.[company_id]

			,wl.[Source Line No_]

			,wl.[Item No_]	

	) rp2

on 

	(

		rp2.[company_id] = sla.[company_id]

	and	rp2.[orderNo] = sla.[Document No_]

	and rp2.itemNo = sla.[Item No]

	and rp2.[Source Line No_] = sla.[Line No_]

	)

outer apply

	(select

		 [Source No_]

		,[Item No_]

		,[Relased to Whse]

		,[Whse No]

        ,[Whse Line No]

	 from

		[ext].[Warehouse_Shipments] ws

	 where

		 ws.[company_id] = sla.[company_id]

	 and ws.[Source No_] = sla.[Document No_]

	 and ws.[Item No_] = sla.[Item No]

	 and ws.[Source Line No_] = sla.[Line No_]

	 and (ws.[Whse No] = rp1.[Whse_ Document No_] or rp1.[Whse_ Document No_] is null)

	 and (ws.[Whse Line No] = rp1.[Whse_ Document Line No_] or rp1.[Whse_ Document Line No_] is null) 

	)

	ws

where

	sh.[Document Type] = 1

GO
