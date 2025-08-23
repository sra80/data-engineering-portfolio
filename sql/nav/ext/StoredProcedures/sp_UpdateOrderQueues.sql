
	

CREATE procedure [ext].[sp_UpdateOrderQueues]

as

set nocount on


/*
alter table [ext].[OrderQueues] drop column [Invoice Date]
alter table [ext].[OrderQueues] drop column [AmountInvoiced]


--OrderCount Update
;with x as
(
select
	[OrderCount], case
		when oq.[Order Line No] = min(oq.[Order Line No]) over (partition by oq.[Order No]) and row_number() over (partition by oq.[Order No],oq.[Order Line No] order by oq.[Order Line No]) = 1  then 1 --03
		else 0
		end [newOrderCount]
from
	[ext].[OrderQueues] oq
--where
--	oq.[Order No] = 'EO-56009222'
)

update x
	set [OrderCount] = [newOrderCount]



--OrderUnits Update
;with x as
(
select
	[OrderUnits], case
		when row_number() over (partition by oq.[Order No],oq.[Order Line No] order by oq.[Order Line No]) = 1 then sla.[Units]
	 else 0
	 end  [newOrderUnits]
from
	[ext].[OrderQueues] oq
join
	(
	select
		 sla.[Location Code]  [Dispatch Location]
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] [Item No]
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
		,sum(sla.[Quantity]) [Units]
		,sum(sla.[Quantity Shipped]) [Qty Shipped]
		,sum(sla.[Quantity Invoiced]) [Qty Invoiced]
		,sum(sla.[Amount]) [Amount]
	from
		ext.Sales_Line_Archive sla--[dbo].[UK$Sales Line Archive] sla
	where
		patindex('ZZ%',sla.[No_]) = 0
	group by
		 sla.[Location Code]  
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] 
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
	) sla
on 
	(
			oq.[Order No] = sla.[Document No_] 
		and oq.[Version No_] = sla.[Version No_]
		and oq.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]
		and oq.[Document Type] = sla.[Document Type]
		--and sha.[Archive Reason] = 3
		--and sha.[Order Date] >= datefromparts(year(getdate())-2,1,1)--datefromparts(year(getdate()),10,24)
	)
--where
--	oq.[Order No] = 'EO-56009222'
)

update x
	set [OrderUnits] = [newOrderUnits]



--Qty Picked By Order Line Update
;with x as
(
select
	[Qty Picked By Order Line], case
		when row_number() over (partition by oq.[Order No],oq.[Order Line No] order by oq.[Order Line No]) = 1 then rp2.SOLinePickQty
	 else 0
	 end  [newQtyPickedByOrderLine]
from
	[ext].[OrderQueues] oq
left join
	(
		select    
			 wl.[Source No_] orderNo
			,wl.[Source Line No_]
			,wl.[Item No_] itemNo
			,sum(wl.[Quantity]) SOLinePickQty
		from
			[ext].[Registered_Pick_Line] wl 
		join
			[ext].[Registered_Pick_Header] wh
		on 
			wh.[No_] = wl.[No_]
		where
			wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
		--and wl.[Action Type] = 2
		group by
				wl.[Source No_]
			,wl.[Source Line No_]
			,wl.[Item No_]
	) rp2
on 
	(
		rp2.[orderNo] = oq.[Order No]
	and rp2.itemNo = oq.[Item No]
	and rp2.[Source Line No_] = oq.[Order Line No]
	)
--where
--	oq.[Order No] = 'EO-56009222'
)
update x
	set [Qty Picked By Order Line] = [newQtyPickedByOrderLine]




--Qty Shipped Update 
;with x as
(
select
	oq.[Qty Shipped], case
		when row_number() over (partition by oq.[Order No],oq.[Order Line No] order by oq.[Order Line No]) = 1 then sla.[Qty Shipped]
	 else 0
	 end  [newQtyShipped]
from
	[ext].[OrderQueues] oq
join
	(
	select
		 sla.[Location Code]  [Dispatch Location]
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] [Item No]
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
		,sum(sla.[Quantity]) [Units]
		,sum(sla.[Quantity Shipped]) [Qty Shipped]
		,sum(sla.[Quantity Invoiced]) [Qty Invoiced]
		,sum(sla.[Amount]) [Amount]
	from
		ext.Sales_Line_Archive sla--[dbo].[UK$Sales Line Archive] sla
	where
		patindex('ZZ%',sla.[No_]) = 0
	group by
		 sla.[Location Code]  
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] 
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
	) sla
on 
	(
			oq.[Order No] = sla.[Document No_] 
		and oq.[Version No_] = sla.[Version No_]
		and oq.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]
		and oq.[Document Type] = sla.[Document Type]
		--and sha.[Archive Reason] = 3
		--and sha.[Order Date] >= datefromparts(year(getdate())-2,1,1)--datefromparts(year(getdate()),10,24)
	)
--where
--	oq.[Order No] = 'EO-56009222'
)

update x
	set [Qty Shipped] = [newQtyShipped]




--Qty Invoiced Update
;with x as
(
select
	oq.[Qty Invoiced], case
		when row_number() over (partition by oq.[Order No],oq.[Order Line No] order by oq.[Order Line No]) = 1 then sla.[Qty Invoiced]
	 else 0
	 end  [newQtyInvoiced]
from
	[ext].[OrderQueues] oq
join
	(
	select
		 sla.[Location Code]  [Dispatch Location]
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] [Item No]
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
		,sum(sla.[Quantity]) [Units]
		,sum(sla.[Quantity Shipped]) [Qty Shipped]
		,sum(sla.[Quantity Invoiced]) [Qty Invoiced]
		,sum(sla.[Amount]) [Amount]
	from
		ext.Sales_Line_Archive sla--[dbo].[UK$Sales Line Archive] sla
	where
		patindex('ZZ%',sla.[No_]) = 0
	group by
		 sla.[Location Code]  
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] 
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
	) sla
on 
	(
			oq.[Order No] = sla.[Document No_] 
		and oq.[Version No_] = sla.[Version No_]
		and oq.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]
		and oq.[Document Type] = sla.[Document Type]
		--and sha.[Archive Reason] = 3
		--and sha.[Order Date] >= datefromparts(year(getdate())-2,1,1)--datefromparts(year(getdate()),10,24)
	)
--where
--	oq.[Order No] = 'EO-56009222'
)

update x
	set [Qty Invoiced] = [newQtyInvoiced]



--OrderAmount Update
;with x as
(
select
	 oq.[OrderAmount], case
		when row_number() over (partition by oq.[Order No],oq.[Order Line No] order by oq.[Order Line No]) = 1 then round(sla.[Amount]/case when ceiling(sha.[Currency Factor]) > 0 then sha.[Currency Factor] else 1 end,2)
	 else 0
	 end [newOrderAmount]
from
	[ext].[OrderQueues] oq
join
	ext.Sales_Header_Archive sha
on
	oq.[Order No] = sha.[No_]
join
	(
	select
		 sla.[Location Code]  [Dispatch Location]
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] [Item No]
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
		,sum(sla.[Quantity]) [Units]
		,sum(sla.[Quantity Shipped]) [Qty Shipped]
		,sum(sla.[Quantity Invoiced]) [Qty Invoiced]
		,sum(sla.[Amount]) [Amount]
	from
		ext.Sales_Line_Archive sla--[dbo].[UK$Sales Line Archive] sla
	where
		patindex('ZZ%',sla.[No_]) = 0
	group by
		 sla.[Location Code]  
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] 
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
	) sla
on 
	(
			sha.[No_] = sla.[Document No_] 
		and sha.[Version No_] = sla.[Version No_]
		and sha.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]
		and sha.[Document Type] = sla.[Document Type]
		--and sha.[Archive Reason] = 3
		and sha.[Order Date] >= datefromparts(year(getdate())-2,1,1)--datefromparts(year(getdate()),10,24)
	)
--where
--	oq.[Order No] = 'EO-56009222'
)

update x
	set [OrderAmount] = [newOrderAmount]




--rn Update
;with x as
(
select
	[rn], row_number() over (partition by oq.[Order No],oq.[Order Line No] order by oq.[Order Line No]) [newrn]
from
	[ext].[OrderQueues] oq
--where
--	oq.[Order No] = 'EO-56009222'
)

update x
	set [rn] = [newrn]



;with x as 
(
select 
	2 [processing_queue]
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
	,[ext].[fn_courier_delivery] (sha.[No_]) [courier_delivery]
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
	ext.Sales_Header_Archive sha--[dbo].[UK$Sales Header Archive] sha
left join
	[dbo].[UK$Inbound Sales Header] ish 
on
	(
		sha.[No_]  = ish.[Document No_] 
	and ish.[Status] = 1
	)
join
	(
	select
		 sla.[Location Code]  [Dispatch Location]
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] [Item No]
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
		,sum(sla.[Quantity]) [Units]
		,sum(sla.[Quantity Shipped]) [Qty Shipped]
		,sum(sla.[Quantity Invoiced]) [Qty Invoiced]
		,sum(sla.[Amount]) [Amount]
	from
		ext.Sales_Line_Archive sla--[dbo].[UK$Sales Line Archive] sla
	where
		patindex('ZZ%',sla.[No_]) = 0
	group by
		 sla.[Location Code]  
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] 
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
	) sla
on 
	(
			sha.[No_] = sla.[Document No_] 
		and sha.[Version No_] = sla.[Version No_]
		and sha.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]
		and sha.[Document Type] = sla.[Document Type]
		--and sha.[Archive Reason] = 3
		and sha.[Order Date] >= datefromparts(year(getdate())-2,1,1)--datefromparts(year(getdate()),10,24)
	)
left join
	(

		select    
			 isnull(wh.[Process End DateTime],isnull(nullif(wl.[Registered DateTime],'17530101'),wh.[Registering Date])) [Pick DateTime]
			,wl.[No_]
			,wl.[Line No_]
			,wl.[Source No_] orderNo
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
			wh.[No_] = wl.[No_]
		where
			wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
		--and wl.[Action Type] = 2
		--and wl.[Source No_] = 'HO-56021004'
		group by
			 isnull(wh.[Process End DateTime],isnull(nullif(wl.[Registered DateTime],'17530101'),wh.[Registering Date]))
			,wl.[No_]
			,wl.[Line No_]
			,wl.[Source No_]
			,wl.[Source Line No_]
			,wl.[Item No_]	
			,wl.[Whse_ Document No_]
			,wl.[Whse_ Document Line No_]
	) rp1
on 
	(
		rp1.[orderNo] = sla.[Document No_]
	and rp1.itemNo = sla.[Item No]
	and rp1.[Source Line No_] = sla.[Line No_]
	)
left join
	(
		select    
			 wl.[Source No_] orderNo
			,wl.[Source Line No_]
			,wl.[Item No_] itemNo
			,sum(wl.[Quantity]) SOLinePickQty
		from
			[ext].[Registered_Pick_Line] wl 
		join
			[ext].[Registered_Pick_Header] wh
		on 
			wh.[No_] = wl.[No_]
		where
			wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
		--and wl.[Action Type] = 2
		group by
				wl.[Source No_]
			,wl.[Source Line No_]
			,wl.[Item No_]
	) rp2
on 
	(
		rp2.[orderNo] = sla.[Document No_]
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
			ws.[Source No_] = sla.[Document No_]
		and ws.[Item No_] = sla.[Item No]
		and ws.[Source Line No_] = sla.[Line No_]
		and (ws.[Whse No] = rp1.[Whse_ Document No_] or rp1.[Whse_ Document No_] is null)
		and (ws.[Whse Line No] = rp1.[Whse_ Document Line No_] or rp1.[Whse_ Document Line No_] is null)
		)
		ws
)

update oq
set 
	oq.[OrderUnits] = x.[OrderUnits],oq.[Qty Shipped] = x.[Qty Shipped], oq.[Qty Invoiced] = x.[Qty Invoiced], oq.[OrderAmount] = x.[OrderAmount]
from
	[ext].[OrderQueues] oq
join
	x
on
	oq.[Whse No] = x.[Whse No]
and oq.[Pick No] = x.[Pick No]
and oq.[Pick Line No] = x.[Pick Line No]
and oq.[Order No] = x.[Order No]
and oq.[Order Line No] =  x.[Order Line No]
and oq.[processing_queue] = x.[processing_queue]

*/


;with x as 
(
select 
	2 [processing_queue]
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
	,[ext].[fn_courier_delivery] (sha.[No_]) [courier_delivery]
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
	ext.Sales_Header_Archive sha--[dbo].[UK$Sales Header Archive] sha
left join
	[dbo].[UK$Inbound Sales Header] ish 
on
	(
		sha.[No_]  = ish.[Document No_] 
	and ish.[Status] = 1
	)
join
	(
	select
		 sla.[Location Code]  [Dispatch Location]
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] [Item No]
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
		,sum(sla.[Quantity]) [Units]
		,sum(sla.[Quantity Shipped]) [Qty Shipped]
		,sum(sla.[Quantity Invoiced]) [Qty Invoiced]
		,sum(sla.[Amount]) [Amount]
	from
		ext.Sales_Line_Archive sla--[dbo].[UK$Sales Line Archive] sla
	where
		patindex('ZZ%',sla.[No_]) = 0
	group by
		 sla.[Location Code]  
		,sla.[Document No_]
		,sla.[Document Type]
		,sla.[No_] 
		,sla.[Line No_]
		,sla.[Version No_]
		,sla.[Doc_ No_ Occurrence]
	) sla
on 
	(
			sha.[No_] = sla.[Document No_] 
		and sha.[Version No_] = sla.[Version No_]
		and sha.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]
		and sha.[Document Type] = sla.[Document Type]
		--and sha.[Archive Reason] = 3
		and sha.[Order Date] >= datefromparts(year(getdate())-2,1,1)--datefromparts(year(getdate()),10,24)
	)
left join
	(

		select    
			 isnull(wh.[Process End DateTime],isnull(nullif(wl.[Registered DateTime],'17530101'),wh.[Registering Date])) [Pick DateTime]
			,wl.[No_]
			,wl.[Line No_]
			,wl.[Source No_] orderNo
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
			wh.[No_] = wl.[No_]
		where
			wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
		--and wl.[Action Type] = 2
		--and wl.[Source No_] = 'HO-56021004'
		group by
			 isnull(wh.[Process End DateTime],isnull(nullif(wl.[Registered DateTime],'17530101'),wh.[Registering Date]))
			,wl.[No_]
			,wl.[Line No_]
			,wl.[Source No_]
			,wl.[Source Line No_]
			,wl.[Item No_]	
			,wl.[Whse_ Document No_]
			,wl.[Whse_ Document Line No_]
	) rp1
on 
	(
		rp1.[orderNo] = sla.[Document No_]
	and rp1.itemNo = sla.[Item No]
	and rp1.[Source Line No_] = sla.[Line No_]
	)
left join
	(
		select    
			 wl.[Source No_] orderNo
			,wl.[Source Line No_]
			,wl.[Item No_] itemNo
			,sum(wl.[Quantity]) SOLinePickQty
		from
			[ext].[Registered_Pick_Line] wl 
		join
			[ext].[Registered_Pick_Header] wh
		on 
			wh.[No_] = wl.[No_]
		where
			wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
		--and wl.[Action Type] = 2
		group by
				wl.[Source No_]
			,wl.[Source Line No_]
			,wl.[Item No_]
	) rp2
on 
	(
		rp2.[orderNo] = sla.[Document No_]
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
			ws.[Source No_] = sla.[Document No_]
		and ws.[Item No_] = sla.[Item No]
		and ws.[Source Line No_] = sla.[Line No_]
		and (ws.[Whse No] = rp1.[Whse_ Document No_] or rp1.[Whse_ Document No_] is null)
		and (ws.[Whse Line No] = rp1.[Whse_ Document Line No_] or rp1.[Whse_ Document Line No_] is null)
		)
		ws
)

update oq
set 
	oq.[OrderUnits] = x.[OrderUnits],oq.[Qty Shipped] = x.[Qty Shipped], oq.[Qty Invoiced] = x.[Qty Invoiced], oq.[OrderAmount] = x.[OrderAmount], oq.[Qty Picked By Order Line] = x.[Qty Picked By Order Line]
from
	[ext].[OrderQueues] oq
join
	x
on
	oq.[Whse No] = x.[Whse No]
and oq.[Pick No] = x.[Pick No]
and oq.[Pick Line No] = x.[Pick Line No]
and oq.[Order No] = x.[Order No]
and oq.[Order Line No] =  x.[Order Line No]
and oq.[processing_queue] = x.[processing_queue]
and oq.[rn] = x.[rn]
GO
