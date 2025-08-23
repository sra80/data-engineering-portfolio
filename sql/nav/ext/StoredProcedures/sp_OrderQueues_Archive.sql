SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create or alter  procedure [ext].[sp_OrderQueues_Archive]

as

set nocount on

if (select datediff(year,getutcdate(),last_processed) from db_sys.procedure_schedule where procedureName = 'ext.sp_OrderQueues_Archive') > 0

	begin

		delete from ext.OrderQueues where processing_queue = 2 and [Order Date] < datefromparts(year(getutcdate())-2,1,1)

		update ext.OrderQueues set processing_queue2 = 200+db_sys.fn_model_partition_month([Order Date]) where processing_queue = 2

	end

declare @t table (id int)

declare @rc int = 1

while @rc > 0

begin

    update
        x
    set
        x.is_oqa_processed = 1
    from
        ext.Sales_Header_Archive x
    join
        (
            select top 10000
                sha.id
            from
				ext.Sales_Header_Archive sha
            join
                ext.OrderQueues oq
            on
                    sha.[company_id] = oq.[company_id]
                and sha.[Document Type] = oq.[Document Type]
                and sha.[No_] = oq.[Order No]
                and sha.[Doc_ No_ Occurrence] = oq.[Doc_ No_ Occurrence]
                and sha.[Version No_] = oq.[Version No_]
            where
                (
                    sha.is_oqa_processed = 0
                )
        ) y
    on
        (
            x.id = y.id
        )

    set @rc = @@rowcount

end

set @rc = 1

while @rc > 0

	begin

		insert into @t (id)
		select top 10000
			id
		from
			ext.Sales_Header_Archive
		where
			(
				is_oqa_processed = 0
			)

		insert into ext.OrderQueues
			(
				[Processing Queue],
				[Order Date],
				[Origin Date],
				[Inbound Date],
				[Order Created Date],
				[Released To Whse Date],
				[Whse No],
                [Whse Line No], --*
				[Picked Date],
				[Pick No],
				[Pick Line No],
				[Integration],
				[Inbound Status],
				[Inbound Error],
				[Country Code],
				[Channel Code],
				[Dispatch Location],
				[Order Status],
				[Warehouse Status],
				[On Hold Code],
				[On Hold Reason],
				[Order No],
				[Order Line No],
				[Item No],
				[picking_required],
				[OrderCount],
				[OrderUnits],
				[Qty Picked By Pick Date],
				[Qty Picked By Order Line],
				[Qty Shipped],
				[Qty Invoiced],
				[processing_queue],
				[processing_queue2],
				[Document Type],
				[Doc_ No_ Occurrence],
				[Version No_],
				[OrderAmount],
				[rn],
				[courier_delivery],
				[company_id]
			)
		select
			'Sales Header Archive' [Processing Queue],
			sub_q.[Order Date],
			sub_q.[Origin Date],
			sub_q.[Inbound Date],
			sub_q.[Order Created Date],
			sub_q.[Released To Whse Date],
			sub_q.[Whse No],
            sub_q.[Whse Line No], --*
			sub_q.[Picked Date],
			sub_q.[Pick No],
			sub_q.[Pick Line No],
			sub_q.[Integration],
			sub_q.[Inbound Status],
			sub_q.[Inbound Error],
			sub_q.[Country Code],
			sub_q.[Channel Code],
			sub_q.[Dispatch Location],
			sub_q.[Order Status],
			sub_q.[Warehouse Status],
			sub_q.[On Hold Code],
			sub_q.[On Hold Reason],
			sub_q.[Order No],
			sub_q.[Order Line No],
			sub_q.[Item No],
			sub_q.[picking_required],
			sub_q.[OrderCount],
			case when sub_q.rn = 1 then sub_q.[OrderUnits_rn1] else 0 end [OrderUnits],
			sub_q.[Qty Picked By Pick Date],
			case when sub_q.rn = 1 then sub_q.[Qty Picked By Order Line_rn1] else 0 end [Qty Picked By Order Line],
			case when sub_q.rn = 1 then sub_q.[Qty Shipped_rn1] else 0 end [Qty Shipped],
			case when sub_q.rn = 1 then sub_q.[Qty Invoiced_rn1] else 0 end [Qty Invoiced],
			sub_q.[processing_queue],
			200+db_sys.fn_model_partition_month(sub_q.[Order Date]),
			sub_q.[Document Type],
			sub_q.[Doc_ No_ Occurrence],
			sub_q.[Version No_],
			case when sub_q.rn = 1 then sub_q.[OrderAmount_rn1] else 0 end [OrderAmount],
			sub_q.[rn],
			sub_q.[courier_delivery],
			sub_q.[company_id]
		from
			(
				select
					sha.[Order Date],
					db_sys.fn_datetime_utc_to_gmt(isnull(ish.[Origin Datetime],sha.[Origin Datetime])) [Origin Date],
					db_sys.fn_datetime_utc_to_gmt(ish.[Created Date Time]) [Inbound Date],
					db_sys.fn_datetime_utc_to_gmt(sha.[Order Created DateTime]) [Order Created Date],
					db_sys.fn_datetime_utc_to_gmt(ws.[Relased to Whse]) [Released To Whse Date],
					isnull(ws.[Whse No],'WAS-00000000') [Whse No],
                    isnull([Whse Line No],1) [Whse Line No],
					db_sys.fn_datetime_utc_to_gmt(rp1.[Pick DateTime]) [Picked Date],
					isnull(rp1.[No_],'WRP-00000000') [Pick No],
					isnull(rp1.[Line No_],1) [Pick Line No],
					sha.[Inbound Integration Code] [Integration],
					db_sys.fn_Lookup('Inbound Sales Header','Status',ish.[Status]) [Inbound Status],
					null [Inbound Error],
					isnull(nullif(sha.[Ship-to Country_Region Code],''),'ZZ') [Country Code],
					sha.[Channel Code],
					sla.[Location Code] [Dispatch Location],
					'Promised' [Order Status],
					'Released' [Warehouse Status],
					0 [On Hold Code],
					null [On Hold Reason],
					sha.[No_] [Order No],
					sla.[Line No_] [Order Line No],
					sla.[No_] [Item No],
					0 [picking_required],
					case when row_number() over (partition by sha.[company_id], sha.[Document Type], sha.[No_], sha.[Doc_ No_ Occurrence], sha.[Version No_] order by sha.[company_id], sha.[Document Type], sha.[No_], sha.[Doc_ No_ Occurrence], sha.[Version No_]) = 1 then 1 else 0 end  [OrderCount],
					sla.Quantity OrderUnits_rn1,
					rp1.PickDocQty [Qty Picked By Pick Date], --to group by pick date, i.e. one order line qty of 2 picked at different times HO-20274279; TURM5060 - joins will split that one order line into two because of 2 pick dates and show picked qty for each pick date
					rp2.SOLinePickQty [Qty Picked By Order Line_rn1],
					sla.[Quantity Shipped] [Qty Shipped_rn1],
					sla.[Quantity Invoiced] [Qty Invoiced_rn1],
					2 [processing_queue],
					sha.[Document Type],
					sha.[Doc_ No_ Occurrence],
					sha.[Version No_],
					round(sla.[Amount]/case when ceiling(sha.[Currency Factor]) > 0 then sha.[Currency Factor] else 1 end,2) [OrderAmount_rn1],
					row_number() over (partition by sla.[company_id], sla.[Document Type], sla.[Document No_], sla.[Doc_ No_ Occurrence], sla.[Version No_], sla.[Line No_] order by sla.[company_id], sla.[Document Type], sla.[Document No_], sla.[Doc_ No_ Occurrence], sla.[Version No_], sla.[Line No_]) rn,
					[logistics].[fn_courier_delivery] (sha.[No_],sha.[company_id]) [courier_delivery],
					sha.[company_id]	
				from
					ext.Sales_Header_Archive sha
				join
					@t t
				on
					(
						sha.id = t.id
					)
				outer apply -- AJ 2023-01-20 12:01:28.330
					(
						select top 1
							[Origin Datetime],
							[Created Date Time],
							[Status]
					from
						[hs_consolidated].[Inbound Sales Header] ish
					where
						(
								sha.[company_id] = ish.[company_id]
							and	sha.[No_] = ish.[Document No_] 
							and ish.[Status] = 1
						)
					) ish
				join
					ext.Sales_Line_Archive sla
				on 
					(
						sha.[company_id] = sla.[company_id]
					and	sha.[No_] = sla.[Document No_] 
					and sha.[Version No_] = sla.[Version No_]
					and sha.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]
					and sha.[Document Type] = sla.[Document Type]
					)
				join
					hs_consolidated.[Item] i
				on
					(
						sla.company_id = i.company_id
					and sla.No_ = i.No_
					and i.[Type] = 0
					)
				left join
					(
						select 
							coalesce(wh.[Process End DateTime],nullif(wl.[Registered DateTime],datefromparts(1753,1,1)),wh.[Registering Date]) [Pick DateTime],
							wl.[No_],
							wl.[Line No_],
							wl.[Source No_] orderNo,
							wl.[company_id],
							wl.[Source Line No_],
							wl.[Item No_] itemNo,
							wl.[Whse_ Document No_],
							wl.[Whse_ Document Line No_],
							sum(wl.[Quantity]) PickDocQty
						from
							[ext].[Registered_Pick_Line] wl 
						join
							[ext].[Registered_Pick_Header] wh
						on
							(
								wh.[company_id] = wl.[company_id]
							and wl.[Activity Type] = wh.[Type]
							and	wh.[No_] = wl.[No_]
							)
						where
							(
								wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
							)
						group by
							coalesce(wh.[Process End DateTime],nullif(wl.[Registered DateTime],datefromparts(1753,1,1)),wh.[Registering Date]),
							wl.[No_],
							wl.[Line No_],
							wl.[Source No_],
							wl.[company_id],
							wl.[Source Line No_],
							wl.[Item No_],
							wl.[Whse_ Document No_],
							wl.[Whse_ Document Line No_]
					) rp1
				on 
					(
						rp1.[company_id] = sla.[company_id]
					and rp1.[orderNo] = sla.[Document No_]
					and rp1.itemNo = sla.[No_]
					and rp1.[Source Line No_] = sla.[Line No_]
					)
				left join
					(
						select
							wl.[company_id],
							wl.[Source No_] orderNo,
							wl.[Source Line No_],
							wl.[Item No_] itemNo,
							sum(wl.[Quantity]) SOLinePickQty
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
							(
								wl.[Activity Type] = 2 --(2 = pick; 3 = movement)
							)
						group by
							wl.[company_id],
							wl.[Source No_],
							wl.[Source Line No_],
							wl.[Item No_]
					) rp2
				on 

					(
						rp2.[company_id] = sla.[company_id]
					and	rp2.[orderNo] = sla.[Document No_]
					and rp2.itemNo = sla.[No_]
					and rp2.[Source Line No_] = sla.[Line No_]
					)
				outer apply
					(
						select top 1
							[Source No_],
							[Item No_],
							[Relased to Whse],
							[Whse No],
                            [Whse Line No] --*
					from
						[ext].[Warehouse_Shipments] ws
					where
						(
							ws.[company_id] = sla.[company_id]
						and ws.[Source No_] = sla.[Document No_]
						and ws.[Item No_] = sla.[No_]
						and ws.[Source Line No_] = sla.[Line No_]
						and 
							(
								ws.[Whse No] = rp1.[Whse_ Document No_]
							or rp1.[Whse_ Document No_] is null
							)
						and 
							(
								ws.[Whse Line No] = rp1.[Whse_ Document Line No_] 
							or rp1.[Whse_ Document Line No_] is null
							)
						)
					) ws
			) sub_q

		update
			sha
		set
			sha.is_oqa_processed = 1
		from
			ext.Sales_Header_Archive sha
		join
			@t t
		on
			(
				sha.id = t.id
			)

		set @rc = @@rowcount

		delete from @t

	end
GO