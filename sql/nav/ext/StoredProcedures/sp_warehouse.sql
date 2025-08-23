


CREATE   procedure [ext].[sp_warehouse]



as



/*


 Description:		Handles data flow in registered picks and posted whse shipments ext. tables

 Project:			142

 Creator:			Ana Jurkic(AJ)

 Copyright:			CompanyX Limited, 2021


MOD	DATE	INITS	COMMENTS


00	211124 	 AJ		Created

01	211124	 AJ		Added Action Type = 2 to insert statement to exclude duplicate lines

02	211125	 AJ		Added [Process End DateTime] to [ext].[Registered_Pick_Header]

03	211129	 AJ		Added [Warehouse Qty Type] and [Box Type Code] to [ext].[Registered_Pick_Header]

04	211129	 AJ		Added Posted Warehouse Shipments

05	211201	 AJ		Changed join to left join to PickQueueLog as some picks are not recorded in the log

06	211202	 AJ		Added keyDeliveryService to [ext].[Registered_Pick_Line] and Whse Shipment Type to [ext].[Registered_Pick_Header]

07	211203	 AJ		Added additional condition for [Warehouse Qty Type] and [Box Type Code] to highlight picks not recorded in Pick Queue Log

08	211206	 AJ		Replaced [Process End DateTime] with [Process Submit DateTime] as in some cases at the time the sp runs the [Process End DateTime] 

					is not populated yet and [Warehouse Qty Type] and [Box Type Code] will be inserted incorrectly

					Added sp_warehouse to be run as part of sp_OrderQueues to ensure data is processed in correct order

09	211210	 AJ		Replaced [Process Submit DateTime] with [Process End DateTime] as it didn't resolve the issue, it seems none of the columns are 

					populated until pick complete - added update & delete statement to resolve the issue and delete picks that haven't completed yet

10	211216	 AJ		Replaced '' [Box Type Code] with 'N/A' as it's causuing an issue in model realtionships

11	211217	 AJ		Removed delete statement as once deleted picks are not re-inserted at a later date

12	211222	 AJ		Added sq.[Process End DateTime] is not null to where statement as otherwise picks in process result in blank values in _code in Pack

					view and the model doesn't allow it

13	220301	 AJ		Change where & delete statements to include data from year before last

14	220426	 AJ		Added update statement for [keyDeliveryService] in [ext].[Registered_Pick_Line] (altered the function to pull from 

					[dbo].[UK$Sales Line Archive] when data not available in [ext].[Sales_Line_Archive]) as it seems on some 

					occasions data not available on 1st insert

15	220704	AJ		Removed Delivery Service

16	220708	AJ		Removed sq.[Process End DateTime] is not null filter as with it in process pickes are not being inserted and 

					update statement then has nothing to update

17	220711	AJ		Added additional condition /*or sq.[Process End DateTime] is null*/ for insatnces where [Pick Queue Entry No_] > 0 but 

					[Process End DateTime] and [Warehouse Qty Type] are still not populated as the pick is in process. Update statement 

					should update both columns on the next run

18	220817	AJ		Commented out the order by from insert into Posted_Whse_Header statement

					Added Shipping Agent & Shipping Agent Service to [ext].[Registered_Pick_Line]

19	230512	AJ      Change made in UAT

				    Introduced @ts table to handle timestamps across companies

				    Removed begin & end timestamps for each table as ts_begin and ts_end will be used from @ts table

					Added [company_id] to insert statements


*/



set nocount on



--Registered Picks



--19

declare @ts table (company_id int, table_name nvarchar(128), ts_begin varbinary(8), ts_end varbinary(8))



        insert into @ts (company_id, table_name, ts_begin, ts_end)

        select

            db_sys.fn_Company(tt.table_name) company_id,

            db_sys.fn_Company_object(tt.table_name) table_name,

            tt.last_timestamp ts_begin,

            isnull(ts_end.ts_end,0) ts_end

        from

            db_sys.timestamp_tracker tt

        left join

            (

                select

                    company_id,

                    'Posted Whse_ Shipment Header' table_name,

                    max([timestamp]) ts_end

                from

                    [hs_consolidated].[Posted Whse_ Shipment Header]

                group by

                    company_id



                union all



                select

                    company_id,

                    'Posted Whse_ Shipment Line' table_name,

                    max([timestamp]) ts_end

                from

                    [hs_consolidated].[Posted Whse_ Shipment Line]

                group by

                    company_id



				union all



				 select

                    company_id,

                    'Registered Whse_ Activity Hdr_' table_name,

                    max([timestamp]) ts_end

                from

                    [hs_consolidated].[Registered Whse_ Activity Hdr_]

                group by

                    company_id

				

				union all



				 select

                    company_id,

                    'Registered Whse_ Activity Line' table_name,

                    max([timestamp]) ts_end

                from

                    [hs_consolidated].[Registered Whse_ Activity Line]

                group by

                    company_id



            ) ts_end

        on

            (

                db_sys.fn_Company(tt.table_name) = ts_end.company_id

            and db_sys.fn_Company_object(tt.table_name) = ts_end.table_name

            )

        where

            (

                tt.stored_procedure = '[ext].[sp_warehouse]'

            )





delete from [ext].[Registered_Pick_Header] where [Registering Date] < datefromparts(year(getdate())-2,1,1) /*13*/ 



delete from [ext].[Registered_Pick_Line] where not exists (select 1 from [ext].[Registered_Pick_Header] where Registered_Pick_Line.[company_id] = Registered_Pick_Header.[company_id] and Registered_Pick_Line.[No_] = Registered_Pick_Header.[No_]) --19





--Registered Pick Header

insert into [ext].[Registered_Pick_Header] ([company_id],[Type],[No_],[Registering Date],[Pick Queue Entry No_],[Process End DateTime],[Warehouse Qty Type],[Box Type Code],[Whse_ Shipment Type]) --19

select

	 x.[company_id] --19

	,x.[Type]

    ,x.[No_]

    ,x.[Registering Date]

	,x.[Pick Queue Entry No_]

    ,sq.[Process End DateTime] --02 & 09

	,case when x.[Pick Queue Entry No_] = 0 or sq.[Process End DateTime] is null then 3 else sq.[Warehouse Qty Type] end [Warehouse Qty Type] --03 & 07 & 17 --case when [Pick Queue Entry No_] = 0 then 3 else [Warehouse Qty Type] end --to add and re-run as full load--3 = Not Recorded; add 4 = Not Applicable to Inbound Sales Header and to all not yet picked after do a full load of OrderQueues, because currentlly all NULL are flagged as 3 and some should be 4

	,case when x.[Pick Queue Entry No_] = 0 then 'Not Recorded' else isnull(nullif(sq.[Box Type Code],''),'N/A') end [Box Type Code] --03 & 07 & 10

	,x.[Whse_ Shipment Type] --06 & 07

from

	[hs_consolidated].[Registered Whse_ Activity Hdr_] x -- 19

left join --05

	[hs_consolidated].[Shipment Preview -PickQueueLog] sq-- 19

on 

	(

		x.[company_id] = sq.[company_id]

	and	x.[Pick Queue Entry No_] = sq.[Entry No_] 

	)

cross apply --19

	@ts ts

where 

	( 

		 x.[company_id] = ts.[company_id] --19

	 and ts.table_name = 'Registered Whse_ Activity Hdr_' --19

	 and x.[timestamp] > ts.ts_begin-- 19 @ts_rp_header_begin 

     and x.[timestamp] <= ts.ts_end -- 19 @ts_rp_header_end 

     and x.[Registering Date] >= datefromparts(year(getdate())-2,1,1) --13

	 --and sq.[Process End DateTime] is not null -- 16

	 and not exists (select 1 from [ext].[Registered_Pick_Header] y where x.[company_id] = y.[company_id] and x.[Type] = y.[Type] and x.[No_] = y.[No_]) --19

	)



update rph --09

	set

		 rph.[Process End DateTime] = sq.[Process End DateTime] 

		,rph.[Warehouse Qty Type] = sq.[Warehouse Qty Type]

		,rph.[Box Type Code] = isnull(nullif(sq.[Box Type Code],''),'N/A') --10

	from

		[ext].[Registered_Pick_Header] rph

	join

		[hs_consolidated].[Shipment Preview -PickQueueLog] sq --19

	on

		(

			rph.[company_id] = sq.[company_id] --19

		and rph.[Pick Queue Entry No_] = sq.[Entry No_]

		)

	where

		rph.[Pick Queue Entry No_] > 0 and rph.[Process End DateTime] is null



--11

--delete from [ext].[Registered_Pick_Header] where [Pick Queue Entry No_] > 0 and [Process End DateTime] is null --09





--Registered Pick Line

insert into [ext].[Registered_Pick_Line] ([company_id],[No_],[Activity Type],[Line No_],[Starting Date],[Registered DateTime],[Whse_ Document Type],[Whse_ Document No_],[Source Type],[Source Line No_],[Source No_],[Item No_]/*,[keyDeliveryService]*/,[Quantity],[Whse_ Document Line No_],[Shipping Agent],[Shipping Agent Service]) --15 & 18 & 19

select

	 x.[company_id] --19

	,x.[No_]

	,x.[Activity Type]

	,x.[Line No_]

	,x.[Starting Date]

	,x.[Registered DateTime]

	,x.[Whse_ Document Type]

	,x.[Whse_ Document No_]

	,x.[Source Type]

	,x.[Source Line No_]

	,x.[Source No_]

	,x.[Item No_]

	--,[ext].[fn_delivery_service] (x.[Source No_]) [keyDeliveryService] --06 --15

	,x.[Quantity]

	,x.[Whse_ Document Line No_]

	,x.[Shipping Agent Code] --18

	,x.[Shipping Agent Service Code] --18

from

	[hs_consolidated].[Registered Whse_ Activity Line] x --19

join

	[ext].[Registered_Pick_Header] z

on

	(

		x.[company_id] = z.[company_id] --19

	and x.[No_] = z.[No_]

	)

cross apply --19

	@ts ts	

where

	(

         x.[company_id] = ts.[company_id] --19

	and ts.table_name = 'Registered Whse_ Activity Line' --19

	and x.[timestamp] > ts.ts_begin -- 19 

    and x.[timestamp] <= ts.ts_end --19

	and x.[Action Type] = 2 --01

    and not exists (select 1 from [ext].[Registered_Pick_Line] y where x.[company_id] = y.[company_id] and x.[No_] = y.[No_] and x.[Activity Type] = y.[Activity Type] and x.[Line No_] = y.[Line No_]) --19

	)





--15

--update x --14

--set [keyDeliveryService] = [ext].[fn_delivery_service] (x.[Source No_])

--from

--	[ext].[Registered_Pick_Line] x

--where

--	[keyDeliveryService] = 'Unknown'





--Posted Warehouse Shipments -- 04



delete from [ext].[Posted_Whse_Line] where [Shipment Created Datetime] < datefromparts(year(getdate())-2,1,1) --13



delete from [ext].[Posted_Whse_Header] where not exists (select 1 from [ext].[Posted_Whse_Line] where Posted_Whse_Header.[company_id] = Posted_Whse_Line.[company_id] and Posted_Whse_Header.[No_] = Posted_Whse_Line.[No_])





--Posted_Whse_Line

insert into [ext].[Posted_Whse_Line] ([company_id],[No_],[Line No_],[Whse_ Shipment No_],[Whse Shipment Line No_],[Shipment Created Datetime],[Quantity],[Location Code],[Channel Code],[Source No_],[Source Line No_],[Item No_]) --19

select 

	 x.[company_id] --19

	,x.[No_]

    ,x.[Line No_]

    ,x.[Whse_ Shipment No_]

	,x.[Whse Shipment Line No_]

    ,x.[Shipment Created Datetime]

    ,x.[Quantity]

    ,x.[Location Code]

    ,x.[Channel Code]

    ,x.[Source No_]

    ,x.[Source Line No_]

    ,x.[Item No_]

from

	[hs_consolidated].[Posted Whse_ Shipment Line] x --19

cross apply --19

	@ts ts

where

	(

         x.[company_id] = ts.[company_id] --19

	and ts.table_name = 'Posted Whse_ Shipment Line' --19

	and x.[timestamp] > ts.ts_begin -- 19 

    and x.[timestamp] <= ts.ts_end --19

	and x.[Shipment Created Datetime] >= datefromparts(year(getdate())-2,1,1) --13

	and not exists (select 1 from [ext].[Posted_Whse_Line] y where x.[company_id] = y.[company_id] and x.[No_] = y.[No_] and x.[Line No_] = y.[Line No_]) --19

	)



--Posted_Whse_Header

insert into [ext].[Posted_Whse_Header] ([company_id],[No_],[Whse_ Shipment Type]) --19

select

	 x.[company_id] --19

	,x.[No_]

	,x.[Whse_ Shipment Type]

from

	[hs_consolidated].[Posted Whse_ Shipment Header] x --19

join

	(select

		 [No_]

		,min([Shipment Created Datetime]) [Shipment Created Datetime]

	from

		[ext].[Posted_Whse_Line] z

	group by

		 [No_]

	) z

on

	(

		x.[company_id] = x.[company_id] --19

	and x.[No_] = z.[No_]

	)

cross apply --19

	@ts ts

where

	(

        x.[company_id] = ts.[company_id] --19

	and ts.table_name = 'Posted Whse_ Shipment Header' --19

	and x.[timestamp] > ts.ts_begin -- 19 

    and x.[timestamp] <= ts.ts_end --19

	and z.[Shipment Created Datetime] >= datefromparts(year(getdate())-2,1,1) --13

	and not exists (select 1 from [ext].[Posted_Whse_Header] y where x.[company_id] = y.[company_id] and x.[No_] = y.[No_]) --19

	)

--18

--order by

--	x.[No_]





 --update timestamp tracker --19

 update tt set

    tt.last_timestamp = ts.ts_end,

    tt.last_update = sysdatetime()

from

    db_sys.timestamp_tracker tt

join

    @ts ts

on

    (

        tt.stored_procedure = '[ext].[sp_warehouse]'

    and db_sys.fn_Company(tt.table_name) = ts.company_id

    and db_sys.fn_Company_object(tt.table_name) = ts.table_name

    )
GO
