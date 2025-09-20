


create or alter procedure [db_sys].[sp_sales_archive_check_logistics_OrderQueues]
	(
		@overide_12h_win bit = 0
	)


as

if @overide_12h_win = 1 or (select datediff(hour,last_update,getutcdate()) from db_sys.datetime_tracker where stored_procedure = 'db_sys.sp_sales_archive_check_logistics_OrderQueues') > 12

begin

if @overide_12h_win = 0 update db_sys.datetime_tracker set last_update = getutcdate() where stored_procedure = 'db_sys.sp_sales_archive_check_logistics_OrderQueues'

--added aditional join to ws (SO-07520732 otherwise duplicated lines for VD-4240) 





/*

order examples

SO-07520732 -- same product on two order lines; same pick no; 2 pick lines; 2 shipment lines - required additional join on ws /(ws.[Whse Line No] = rp1.[Whse_ Document Line No_] or rp1.[Whse_ Document Line No_] is null)/

HO-20274279 -- one order line TURM5060 qty of 2 picked at different times -- requred rp1 and rp2 joins to split one order line into two because of 2 pick dates and show picked qty for each pick date (rp1) and and show total line qty in only first line (rp2)			 

SO-07418002 -- two order lines of the same product GLM50120 released to same shipment but two different lines - required additional join on ws /ws.[Source Line No_] = sla.[Line No_]/ to avoid duplication of lines and resulting in 4 instead of 2 lines



*/



-- 230406 added process = 1 flags for 'Sales_Header_Archive' and 'Picked Shipments P01'



exec db_sys.sp_auditLog_procedure @procedureName='[ext].[sp_OrderQueues]', @parent_procedureName='[db_sys].[sp_sales_archive_check_logistics_OrderQueues]' -- error email 26/11/2021 21:16 PK violation (WAS-00943340, WRP-00464108, 240000, HO-56166379, 30000, GLCX060) as this procedure was triggerred for processing, sp_OrderQueues was last run @20:55 so HO-56166379 still wasn't deleted with Processing Queue = Sales Header

insert into [ext].[OrderQueues] ([company_id],[processing_queue],[Processing Queue],[Order Date],[Origin Date],[Inbound Date],[Order Created Date],[Released To Whse Date],[Whse No],[Picked Date],[Pick No],[Pick Line No],[Integration],[Inbound Status],[Inbound Error],[Country Code],[Channel Code],[Dispatch Location], [courier_delivery], [Order Status],[Warehouse Status],[On Hold Code],[On Hold Reason],[Order No],[Order Line No],[Item No],[picking_required],[OrderCount],[OrderUnits],[Qty Picked By Pick Date],[Qty Picked By Order Line],[OrderAmount],[Qty Shipped],[Qty Invoiced],[rn],[Document Type],[Doc_ No_ Occurrence],[Version No_])

select 

	sha.[company_id]

	,2 [processing_queue]

	,'Sales Header Archive' [Processing Queue]

	,sha.[Order Date]

	,case

		when coalesce(convert(datetime,switchoffset(ish.[Origin Datetime],datepart(tzoffset,ish.[Origin Datetime] at time zone 'GMT Standard Time'))),convert(datetime,switchoffset(sha.[Origin Datetime],datepart(tzoffset,sha.[Origin Datetime] at time zone 'GMT Standard Time')))) = '17530101' then coalesce(convert(datetime,switchoffset(ish.[Created Date Time],datepart(tzoffset,ish.[Created Date Time] at time zone 'GMT Standard Time'))),convert(datetime, switchoffset(sha.[Order Created DateTime], datepart(tzoffset,sha.[Order Created DateTime] at time zone 'GMT Standard Time'))))

		else coalesce(convert(datetime,switchoffset(ish.[Origin Datetime],datepart(tzoffset,ish.[Origin Datetime] at time zone 'GMT Standard Time'))),convert(datetime,switchoffset(sha.[Origin Datetime],datepart(tzoffset,sha.[Origin Datetime] at time zone 'GMT Standard Time'))))

		end [Origin Date]

	,convert(datetime,switchoffset(ish.[Created Date Time],datepart(tzoffset,ish.[Created Date Time] at time zone 'GMT Standard Time'))) [Inbound Date]

	,convert(datetime, switchoffset(sha.[Order Created DateTime], datepart(tzoffset,sha.[Order Created DateTime] at time zone 'GMT Standard Time'))) [Order Created Date]

	,convert(datetime, switchoffset(ws.[Relased to Whse], datepart(tzoffset,ws.[Relased to Whse] at time zone 'GMT Standard Time'))) [Relased to Whse]

	,isnull(ws.[Whse No],'WAS-00000000') [Whse No]

	,convert(datetime, switchoffset(rp1.[Pick DateTime], datepart(tzoffset,rp1.[Pick DateTime] at time zone 'GMT Standard Time'))) [Picked Date]

	,isnull(rp1.[No_],'WRP-00000000') [Pick No]

	,isnull(rp1.[Line No_],1) [Pick Line No]

	,sha.[Inbound Integration Code] [Integration]

	,case

		when ish.[Status] = 0 then 'Awaiting Processing'

		when ish.[Status] = 1 then 'Processed'

		when ish.[Status] = 2 then 'Errored'

		when ish.[Status] = 3 then 'Cancelled'

	end [Inbound Status]

	,null [Inbound Error]

	,isnull(nullif(sha.[Ship-to Country_Region Code],''),'ZZ') [Country Code]

	,sha.[Channel Code]

	,sla.[Dispatch Location]

	--,[ext].[fn_delivery_service] (sha.[No_]) [Delivery Service]

	,[logistics].[fn_courier_delivery] (sha.[No_],sha.[company_id]) [courier_delivery]

	,'Promised' [Order Status]

	,'Released' [Warehouse Status]

	,0 [On Hold Code]

	,null [On Hold Reason]

	,sha.[No_] [Order No]

	,sla.[Line No_] [Order Line No]

	,sla.[Item No]

	,0 [picking_required]

	,case

		when sla.[Line No_] = min(sla.[Line No_]) over (partition by sla.[Document No_]) and row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1  then 1 --03

		--when row_number() over (partition by sla.[Document Type],sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1 then 1 --01

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

		when row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) = 1 then round(sla.[Amount]/case when ceiling(sha.[Currency Factor]) > 0 then sha.[Currency Factor] else 1 end,2)

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

	,sha.[Document Type]

	,sha.[Doc_ No_ Occurrence]

	,sha.[Version No_]

	,row_number() over (partition by sla.[Document No_],sla.[Line No_] order by sla.[Line No_]) [rn]

from

	ext.Sales_Header_Archive sha

outer apply -- AJ 2023-01-20 12:01:28.330

	(

		select top 1 [ID]

		,[company_id]

		,[Origin Datetime]

		,[Created Date Time]

		,[Status]

		,[Document No_]

	from

		[consolidated].[Inbound Sales Header] ish

	where

		(

			sha.[company_id] = ish.[company_id]

		and	sha.[No_] = ish.[Document No_] 

		and ish.[Status] in (1)

		)

	)

	ish

join

	(

	select

		 sla.[Location Code]  [Dispatch Location]

		,sla.[Document No_]

		,sla.[Document Type]

		,sla.[company_id]

		,sla.[No_] [Item No]

		,sla.[Line No_]

		,sla.[Version No_]

		,sla.[Doc_ No_ Occurrence]

		,sum(sla.[Quantity]) [Units]

		,sum(sla.[Quantity Shipped]) [Qty Shipped]

		,sum(sla.[Quantity Invoiced]) [Qty Invoiced]

		,sum(sla.[Amount]) [Amount]

	from

		ext.Sales_Line_Archive sla

	where

		patindex('ZZ%',sla.[No_]) = 0

	group by

		 sla.[Location Code]  

		,sla.[Document No_]

		,sla.[Document Type]

		,sla.[company_id]

		,sla.[No_] 

		,sla.[Line No_]

		,sla.[Version No_]

		,sla.[Doc_ No_ Occurrence]

	) sla

on 

	(

			sha.[company_id] = sla.[company_id]

		and	sha.[No_] = sla.[Document No_] 

		and sha.[Version No_] = sla.[Version No_]

		and sha.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]

		and sha.[Document Type] = sla.[Document Type]

		and sha.[Order Date] >= datefromparts(year(getdate())-2,1,1)

	

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

		--and wl.[Source No_] = 'HO-56021004'

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

	not exists (select 1 from ext.[OrderQueues] oq where oq.[company_id] = sha.[company_id] and oq.[Whse No] = isnull(ws.[Whse No],'WAS-00000000') and oq.[Pick No] = isnull(rp1.[No_],'WRP-00000000') and oq.[Pick Line No] = isnull(rp1.[Line No_],1) and oq.[Order No] = sha.[No_] and oq.[Order Line No] = sla.[Line No_] and oq.[Item No] = sla.[Item No] and [processing_queue] = 2)



--below 2 partitions are added in [db_sys].[process_model_partitions_procedure_pairing] and the process is actually the other way around as partitions are triggering the sp to run before the partitions are processed

--update db_sys.process_model_partitions set process = 1 where model_name = 'Logistics_OrderQueues' and table_name = 'OrderQueues' and partition_name = 'Sales_Header_Archive' and (select disable_process from db_sys.process_model where model_name = 'Logistics_OrderQueues') = 0 
--update db_sys.process_model_partitions set process = 1 where model_name = 'Logistics_OrderQueues' and table_name = 'Picked Shipments' and partition_name = 'P01' and (select disable_process from db_sys.process_model where model_name = 'Logistics_OrderQueues') = 0
 end

 go