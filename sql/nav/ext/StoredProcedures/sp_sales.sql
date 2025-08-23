create or alter procedure [ext].[sp_sales]
    (
        @process_archive bit = 0,
        @overide_12h_win bit = 0
    )

as

/*
 Description:		Handles data flow in sales orders ext. tables
 Project:			112
 Creator:			Shaun Edwards(SE)
 Copyright:			CompanyX Limited, 2021
MOD	DATE	INITS	COMMENTS
00
01
02
03
04 211108   SE      Unknown
05 211115   SE      Add handling for Archive tables
06 211117   SE      Flag archive partitions in sales order model for processing when archive is processed
07 211119   SE      Removal of setting archive partitions to process, this is inline with the change to model dependency on procedures with the creation and implementation of the db_sys.process_model_partitions_procedure_pairing
08 211120   SE      Instead of looking at AutoNAV, remove orders no longer in a Promised state if order is before today
09 211123   SE      Restore logic pre , reduce delay for clearing down sales no longer in a promised state in sales table from 6 hours down to 2
10 211125   SE      Refering back to 6 hour wait
11 211127   SE      Still having issues with sales disappearing from the model. Clearing down Sales Header & Line (not archive) now happens as part of archive logic (@process_archive = 1), deletion logic changed for orders no longer a sale (usually due to being re-opened or cancelled)
12 211129   SE      Delete from ext sales line where not in dbo sales line - can happen where a line is removed from an order
13 211129   SE      Undid , this could remove lines in the middle of archive process
14 211210   SE      To ext.Sales_Header_Archive add columns [Inbound Integration Code],[Order Created DateTime],[Origin Datetime], to ext.Sales_Header add columns [Inbound Integration Code],[Origin Datetime]
15 211210   SE      Flag db_sys.process_model_partitions set process = 1 where model_name = 'Logistics_OrderQueues' and table_name = 'OrderQueues' and partition_name = 'Sales_Header_Archive' for process
                    Merge Sales Header, Sales Line, required for Logistics_OrderQueues model to see changes throughout order process flow, includes checksum on header and line and additional fields required for the model
16  220105  SE      [db_sys].[sp_sales_archive_check_logistics_OrderQueues] and associated partition process flag commented out due to issues with the procedure (taking over 5 hours to process) 
17  220110  SE      [db_sys].[sp_sales_archive_check_logistics_OrderQueues] re-enabled  
18  220302  SE      Set Media Code to null if blank
19  221003  SE      Populate [External Document No_], populate table ext.External_Document_Number
20  221024  SE      Populate [Dimension Set ID] in ext.Sales_Line_Archive
21  221107  SE      Remove deleted sales from Sales_Header and Sales_Line as soon as they are flagged as deleted/removed in the archive
22  221112  SE      Ref ticket 21746, error occurs ref , removing deleted sales when processing archive 
23	221114	AJ		Ref 21739, flag db_sys.process_model_partitions set process = 1 where model_name = 'Logistics_OrderQueues' and table_name = 'Picked Shipments' and partition_name = 'P01' for process
24  230215  SE      Add New Zealand sales data, update hs_identity_link.Customer where @process_archive = 1
25  230228  SE      Add Netherlands & Ireland sales data
26  230315  SE      Optimizations:
                    - aggregate code across companies
                    - stop populating ord_count in Sale Line & Sale Line Archive (changed to accept null)
                    - stop populating cost_center_code in Sale Line Archive (changed to accept null)
27  230503  SE      Add db_sys.sp_model_partition_month procedure for Archive partition schedule handling
28  230822  SE      Add User ID Detail to Header tables
29  230824  SE      Add [Subscription No_]  to Sales Header & Sales Header Archive
30  230913  SE      Add outcode_id to Sales Header & Sales Header Archive (ref db_sys.outcode) for UK geographical data for material wastage reporting, ref ticket 21311
31  230920  SE      Add id to sale line (from sequence ext.sq_sales_line)
                    Add type to sale line (from source)
32  231013  SE      Populate is in ext.Sales_Line_Archive where null, e.g. Shop sales go straight to archive
33  231212  SE      Removal of timestamp tracking, ref ticket 34926, checking overnight processes following this change on 231213, runtime was slightly less than the previous execution ID_auditLog: 674637
34  231219  SE      Add [Outstanding Quantity] to ext.Sales_Line
35  240129  SE      Add [BOM Item No_] to ext.Sales_Line and ext.Sales_Line_Archive
36  240501  SE      Set @process_archive = 0 if run in last 12 hours
37  240517  SE      Revise , use db_sys.datetime_tracker to better workout the last true run of the archive process
38  240528  SE      Add id for ext.Sales_Header and ext.Sales_Header_Archive (from sequence ext.sq_sales_header)
39  240531  SE      Fix ref 30577, company_id in function [ext].[fn_payment_method] hard set to 5 (NZ)
                    Moved lookup away from function and added an outer apply to lookup the Payment Method (the method which contributed the highest settlement value)
40  240618  SE      Introduction of hashbyte value, the intention is for this to replace checksum as it's more accurate
                    Get [Sales Order Status] from the [Sales Header Archive] if it exists, otherwise reference from [Sales Header] - needed for Shop sales
41  240620  SE      Refer to stg tables for processing archive
42  241202  SE/AJ   Add partition scheduling for Logistics_OrderQueues 
*/

set nocount on

declare @auditLog_ID int, @place_holder uniqueidentifier = newid(), @process_archive_check bit = 0

if @process_archive = 0 select @place_holder = place_holder from db_sys.procedure_schedule where procedureName = 'ext.sp_sales'

if @process_archive = 1 select @place_holder = place_holder from db_sys.procedure_schedule where procedureName = 'ext.sp_sales @process_archive = 1' -- fix

select @auditLog_ID = ID from db_sys.auditLog where try_convert(uniqueidentifier,eventDetail) = @place_holder

-- if (select datediff(hour,db_sys.fn_datetime_utc_to_gmt(last_processed),db_sys.fn_datetime_utc_to_gmt(getutcdate())) from db_sys.procedure_schedule where procedureName = 'ext.sp_sales @process_archive = 1') <= 12 set @process_archive = 0 --

--remove non-final copies from the stage ***start
delete from
    s
from
    stg.Sales_Line_Archive s
join 
    hs_consolidated.[Sales Header Archive] d 
on 
    (
        s.company_id = d.company_id
    and s.[Document Type] = d.[Document Type] 
    and s.[Document No_] = d.[No_] 
    and s.[Doc_ No_ Occurrence] = d.[Doc_ No_ Occurrence]
    and s.[Version No_] = d.[Version No_]
    )
where
    (
        d.[Archive Reason] > 3
    or  d.[Archive Reason] < 3
    or  d.[Order Date] < datefromparts(year(getdate())-2,1,1)
    )

delete from
    s
from 
    stg.Sales_Header_Archive s
join 
    hs_consolidated.[Sales Header Archive] d 
on 
    (
        s.company_id = d.company_id
    and s.[Document Type] = d.[Document Type] 
    and s.[No_] = d.[No_] 
    and s.[Doc_ No_ Occurrence] = d.[Doc_ No_ Occurrence] 
    and s.[Version No_] = d.[Version No_]
    )
where
    (
        d.[Archive Reason] > 3
    or  d.[Archive Reason] < 3
    or  d.[Order Date] < datefromparts(year(getdate())-2,1,1)
    )
--remove non-final copies from the stage ***end

if @process_archive = 1 and @overide_12h_win = 0 and (select datediff(hour,last_update,getutcdate()) from db_sys.datetime_tracker where stored_procedure = 'ext.sp_sales @process_archive = 1') > 12 --

begin

update db_sys.datetime_tracker set last_update = getutcdate() where stored_procedure = 'ext.sp_sales @process_archive = 1'

set @process_archive_check = 1

end

if @process_archive = 1 and (@process_archive_check = 1 or @overide_12h_win = 1)

    begin /*archive***start*/

        --check for new users  ***start 
        insert into db_sys.Users (ad_id)
        select
            x.ad_id
        from
            (
                select distinct
                    [Order Created by] ad_id
                from 
                    [hs_consolidated].[Sales Header Archive]
                where
                    [Archive Reason] = 3
            ) x
        left join
            db_sys.Users u
        on
            (
                x.ad_id = u.ad_id
            )
        where
            (
                u.ad_id is null
            )
        --check for new users  ***end 

        /**/
        exec db_sys.sp_model_partition_month @model_name='Marketing_SalesOrders',@table_name='SalesOrders',@partition_name_prefix='SalesOrders_Archive_',@auditLog_ID=@auditLog_ID

        /**/
        exec db_sys.sp_model_partition_month @model_name='Logistics_OrderQueues',@table_name='OrderQueues',@partition_name_prefix='Sales_Header_Archive_2',@auditLog_ID=@auditLog_ID

        --clear the stage ***start
        delete from
            s
        from 
            stg.Sales_Header_Archive s
        join 
            ext.Sales_Header_Archive d 
        on 
            (
                s.company_id = d.company_id
            and s.[Document Type] = d.[Document Type] 
            and s.[No_] = d.[No_] 
            and s.[Doc_ No_ Occurrence] = d.[Doc_ No_ Occurrence] 
            and s.[Version No_] = d.[Version No_]
            )

        delete from
            s
        from 
            stg.Sales_Line_Archive s
        join 
            ext.Sales_Line_Archive d 
        on 
            (
                s.company_id = d.company_id
            and s.[Document Type] = d.[Document Type]
            and s.[Document No_] = d.[Document No_] 
            and s.[Doc_ No_ Occurrence] = d.[Doc_ No_ Occurrence] 
            and s.[Version No_] = d.[Version No_]
            and s.[Line No_] = d.[Line No_]
            )
        --clear the stage ***end

        --set place_holder to stage ***start
        update
            h
        set
            h.place_holder = @place_holder,
            h.archiveTS = getutcdate()
        from
            stg.Sales_Header_Archive h
        join
            stg.Sales_Line_Archive l
        on
            (
                h.company_id = l.company_id
            and h.[Document Type] = l.[Document Type] 
            and h.[No_] = l.[Document No_] 
            and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence] 
            and h.[Version No_] = l.[Version No_]
            )

        update
            l
        set
            l.place_holder = h.place_holder,
            l.archiveTS = getutcdate()
        from
            stg.Sales_Header_Archive h
        join
            stg.Sales_Line_Archive l
        on
            (
                h.company_id = l.company_id
            and h.[Document Type] = l.[Document Type] 
            and h.[No_] = l.[Document No_] 
            and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence] 
            and h.[Version No_] = l.[Version No_]
            )
        where
            (
                h.place_holder = @place_holder
            )
        --set place_holder to stage ***end

        delete from ext.Sales_Header_Archive where [Order Date] < datefromparts(year(getdate())-2,1,1)

        delete from ext.Sales_Line_Archive where not exists (select 1 from ext.Sales_Header_Archive where Sales_Line_Archive.company_id = Sales_Header_Archive.company_id and Sales_Line_Archive.[Document Type] = Sales_Header_Archive.[Document Type] and Sales_Line_Archive.[Document No_] = Sales_Header_Archive.[No_] and Sales_Line_Archive.[Doc_ No_ Occurrence] = Sales_Header_Archive.[Doc_ No_ Occurrence] and Sales_Line_Archive.[Version No_] = Sales_Header_Archive.[Version No_])

        insert into ext.Sales_Header_Archive (company_id, [Document Type],[No_],[Doc_ No_ Occurrence],[Version No_],[Sell-to Customer No_],[Order Date],[Ship-to Country_Region Code],[Channel Code],[Media Code],[Payment Method Code],[Currency Factor],customer_status,[Inbound Integration Code],[Order Created DateTime],[Origin Datetime],[External Document No_], [Created By ID], [Subscription No_], [outcode_id], [id])
        select
            d.company_id,
            d.[Document Type],
            d.[No_],
            d.[Doc_ No_ Occurrence],
            d.[Version No_],
            d.[Sell-to Customer No_],
            d.[Order Date],
            d.[Ship-to Country_Region Code],
            d.[Channel Code],
            nullif(d.[Media Code],''),
            isnull(pm.[Payment Method Code],d.[Payment Method Code]),
            ext.fn_Convert_CurrencyFactor_GBP(d.[Currency Factor],d.company_id,d.[Order Date]) [Currency Factor],
            ext.fn_Customer_Status(d.company_id, d.[Sell-to Customer No_],d.[Order Date]),
            nullif(d.[Inbound Integration Code],''),
            d.[Order Created DateTime],
            d.[Origin Datetime],
            isnull(nullif(d.[External Document No_],''),d.No_),
            (select ID from db_sys.Users u where u.ad_id = d.[Order Created by]), /**/
            nullif(d.[Subscription No_],''),
            db_sys.fn_outcode(d.[Ship-to Post Code],d.[Ship-to Country_Region Code]),
            (select id from ext.Sales_Header x where x.company_id = d.company_id and x.[No_] = d.[No_] and x.[Document Type] = d.[Document Type]) --
        from 
            [hs_consolidated].[Sales Header Archive] d
        join
            stg.Sales_Header_Archive s
        on
            (
                s.company_id = d.company_id
            and s.[Document Type] = d.[Document Type] 
            and s.[No_] = d.[No_] 
            and s.[Doc_ No_ Occurrence] = d.[Doc_ No_ Occurrence] 
            and s.[Version No_] = d.[Version No_]
            )
        outer apply --
            (
                select top 1
                    nullif(pr.[Payment Method Code],'') [Payment Method Code]
                from
                    hs_consolidated.[Payment_Refund] pr
                where
                    (
                        pr.company_id = d.company_id
                    and pr.[Buying Reference No_] = d.[External Document No_]
                    )
                order by
                    [Collected Amount (LCY)] desc
            ) pm
        where 
            (
                d.[Archive Reason] = 3
            and s.place_holder = @place_holder
            )

        --Populate is in ext.Sales_Line_Archive where null, e.g. Shop sales go straight to archive 
        update ext.Sales_Header_Archive set id = next value for ext.sq_sales_header where id is null

        insert into ext.Sales_Line_Archive (company_id, [Document Type],[Document No_],[Doc_ No_ Occurrence],[Version No_],[Line No_],[Location Code],[Delivery Service],[No_],[Quantity],[Quantity Shipped],[Quantity Invoiced],[Promotion Discount Amount],[Line Discount Amount],[Amount Including VAT],[Amount],[Dimension Set ID],id,sales_header_id,[Type],[BOM Item No_])
        select
            d.company_id,
            d.[Document Type],
            d.[Document No_],
            d.[Doc_ No_ Occurrence],
            d.[Version No_],
            d.[Line No_],
            nullif(d.[Location Code],''),
            nullif(d.[Delivery Service],''),
            d.[No_],
            d.[Quantity],
            d.[Quantity Shipped],
            d.[Quantity Invoiced],
            ext.fn_Convert_Currency_GBP(d.[Promotion Discount Amount],d.company_id,h.[Order Date]),
            ext.fn_Convert_Currency_GBP(d.[Line Discount Amount],d.company_id,h.[Order Date]),
            ext.fn_Convert_Currency_GBP(d.[Amount Including VAT],d.company_id,h.[Order Date]),
            ext.fn_Convert_Currency_GBP(d.[Amount],d.company_id,h.[Order Date]),
            d.[Dimension Set ID],
            (select id from ext.Sales_Line x where x.company_id = d.company_id and x.[Document Type] = d.[Document Type] and x.[Document No_] = d.[Document No_] and x.[Line No_] = d.[Line No_]),
            h.id,
            d.[Type],
            nullif(d.[BOM Item No_],'')
        from 
            [hs_consolidated].[Sales Line Archive] d 
        join
            ext.Sales_Header_Archive h
        on
            (
                d.company_id = h.company_id
            and d.[Document Type] = h.[Document Type]
            and d.[Document No_] = h.[No_]
            and d.[Doc_ No_ Occurrence] = h.[Doc_ No_ Occurrence]
            and d.[Version No_] = h.[Version No_]
            )
        join
            stg.Sales_Line_Archive s
        on
            (
                s.company_id = d.company_id
            and s.[Document Type] = d.[Document Type] 
            and s.[Document No_] = d.[Document No_] 
            and s.[Doc_ No_ Occurrence] = d.[Doc_ No_ Occurrence] 
            and s.[Version No_] = d.[Version No_]
            and s.[Line No_] = d.[Line No_]
            )
        where
            (
                s.place_holder = @place_holder
            )

        --Populate is in ext.Sales_Line_Archive where null, e.g. Shop sales go straight to archive 
        update ext.Sales_Line_Archive set id = next value for ext.sq_sales_line where id is null

        --Sales Cleanup
        --delete where exists in archive
        delete from ext.Sales_Header where exists (select 1 from ext.Sales_Header_Archive where Sales_Header.company_id = Sales_Header_Archive.company_id and Sales_Header.[Document Type] = Sales_Header_Archive.[Document Type] and Sales_Header.No_ = Sales_Header_Archive.No_)
        delete from ext.Sales_Line where exists (select 1 from ext.Sales_Line_Archive where Sales_Line.company_id = Sales_Line_Archive.company_id and Sales_Line.[Document Type] = Sales_Line_Archive.[Document Type] and Sales_Line.[Document No_] = Sales_Line_Archive.[Document No_] and Sales_Line.[Line No_] = Sales_Line_Archive.[Line No_])

        --delete where does not exist in archive and NAV sales header order is more than a day old
        delete from 
            ext.Sales_Header
        where 
            (
                not exists (select 1 from [hs_consolidated].[Sales Header] nav where Sales_Header.company_id = nav.company_id and Sales_Header.[Document Type] = nav.[Document Type] and Sales_Header.No_ = nav.No_)
            and datediff(day,[Order Date],getutcdate()) > 1
            and datediff(day,[Order Date],(select max([Order Date]) from ext.Sales_Header_Archive)) > 1
            )

        delete from
            ext.Sales_Line
        where
            (
                not exists (select 1 from ext.Sales_Header h where Sales_Line.company_id = h.company_id and Sales_Line.[Document No_] = h.No_ and Sales_Line.[Document Type] = h.[Document Type])
            )

        -- populate table ext.External_Document_Number
        insert into ext.External_Document_Number (company_id, [External Document No_])
        select
            company_id,
            [External Document No_]
        from
            ext.Sales_Header_Archive sha
        where
            (
                not exists (select 1 from ext.External_Document_Number edn where sha.company_id = edn.company_id and sha.[External Document No_] = edn.[External Document No_])
            )

        --update hs_identity_link.Customer***start

        merge 
            hs_identity_link.Customer t
        using 
            (
                select
                    sales.customer_id, x.company_id, x.platform, x.channel, x.order_date
                from
                    (
                        select
                            customer_id
                        from
                            ext.[Sales_Header]
                        where
                            [Sales Order Status] = 1

                        union

                        select
                            customer_id
                        from
                            ext.[Sales_Header_Archive]
                        where
                            (
                                [Order Date] >= dateadd(week,-4,sysdatetime())
                            )
                    ) sales
                cross apply
                    hs_identity_link.fn_Customer(sales.customer_id) x 
            ) s
        on
            (
                t.ID = s.customer_id
            )
        when matched and (t.first_order > s.order_date) then update set
            t.first_company = s.company_id,
            t.first_platform = s.platform,
            t.first_channel = s.channel,
            t.first_order = s.order_date,
            t.updatedTSUTC = sysdatetime()
        when not matched by target then
            insert (ID, first_company, first_platform, first_channel, first_order)
            values (s.customer_id, s.company_id, s.platform, s.channel, s.order_date)
        when not matched by source and t.first_order >= dateadd(week,-4,sysdatetime()) then update set
            t.first_company = null,
            t.first_platform = null,
            t.first_channel = null,
            t.first_order = null,
            t.updatedTSUTC = sysdatetime();

    --update hs_identity_link.Customer***end

        --below commented out due to issues with the procedure [db_sys].[sp_sales_archive_check_logistics_OrderQueues] which is taking in excess of 5 hours to run
        
        -- exec db_sys.sp_auditLog_procedure '[db_sys].[sp_sales_archive_check_logistics_OrderQueues]'
        
        -- update db_sys.process_model_partitions set process = 1 where model_name = 'Logistics_OrderQueues' and table_name = 'OrderQueues' and partition_name = 'Sales_Header_Archive' and (select disable_process from db_sys.process_model where model_name = 'Logistics_OrderQueues') = 0 --
		
		-- update db_sys.process_model_partitions set process = 1 where model_name = 'Logistics_OrderQueues' and table_name = 'Picked Shipments' and partition_name = 'P01' and (select disable_process from db_sys.process_model where model_name = 'Logistics_OrderQueues') = 0 --
    
    end /*archive***end*/

--check for new users  ***start 
insert into db_sys.Users (ad_id)
select
    x.ad_id
from
    (
        select
            [Created by] ad_id
        from 
            [hs_consolidated].[Sales Header]

        union

        select
            [Order Created by] ad_id
        from 
            [hs_consolidated].[Sales Header Archive]
    ) x
left join
    db_sys.Users u
on
    (
        x.ad_id = u.ad_id
    )
where
    (
        u.ad_id is null
    )
--check for new users  ***end 

--sales header
merge ext.Sales_Header t
using
    (
        select 
            d.company_id,
            d.[No_],
            d.[Document Type],
            d.[Sell-to Customer No_],
            d.[Order Date],
            d.[Ship-to Country_Region Code],
            d.[Channel Code],
            nullif(d.[Media Code],'') [Media Code],
            isnull(pm.[Payment Method Code],d.[Payment Method Code]) [Payment Method Code],
            ext.fn_Convert_CurrencyFactor_GBP(d.[Currency Factor],d.company_id,d.[Order Date]) [Currency Factor],
            ext.fn_Customer_Status(d.company_id, d.[Sell-to Customer No_],d.[Order Date]) customer_status,
            nullif(d.[Inbound Integration Code],'') [Inbound Integration Code],
            d.[Origin Datetime],
            d.[Created DateTime],
            isnull((select [Sales Order Status] from hs_consolidated.[Sales Header Archive] x where x.company_id = d.company_id and x.[No_] = d.[No_] and x.[Document Type] = d.[Document Type] and x.[Archive Reason] = 3),d.[Sales Order Status]) [Sales Order Status], --
            d.[Status],
            nullif(d.[On Hold],'') [On Hold],
            checksum(d.[Sell-to Customer No_],d.[Order Date],d.[Ship-to Country_Region Code],d.[Channel Code],d.[Media Code],isnull(pm.[Payment Method Code],d.[Payment Method Code]),d.[Currency Factor],nullif(d.[Inbound Integration Code],''),d.[Origin Datetime],d.[Created DateTime],d.[Sales Order Status],d.[Status],nullif(d.[On Hold],''),d.[Created by],d.[Subscription No_],db_sys.fn_outcode(d.[Ship-to Post Code],d.[Ship-to Country_Region Code]),ext.fn_Customer_Status(d.company_id, d.[Sell-to Customer No_],d.[Order Date])) dbo_checksum,
            isnull(nullif(d.[External Document No_],''),d.No_) [External Document No_],
            (select ID from db_sys.Users where Users.ad_id = d.[Created by]) [Created By ID], /**/
            nullif(d.[Subscription No_],'') [Subscription No_],
            db_sys.fn_outcode(d.[Ship-to Post Code],d.[Ship-to Country_Region Code]) outcode_id,
            convert(varbinary(16),hashbytes('MD5',concat(d.[Sell-to Customer No_],d.[Order Date],d.[Ship-to Country_Region Code],d.[Channel Code],d.[Media Code],isnull(pm.[Payment Method Code],d.[Payment Method Code]),d.[Currency Factor],nullif(d.[Inbound Integration Code],''),d.[Origin Datetime],d.[Created DateTime],d.[Sales Order Status],d.[Status],nullif(d.[On Hold],''),d.[Created by],d.[Subscription No_],db_sys.fn_outcode(d.[Ship-to Post Code],d.[Ship-to Country_Region Code]),ext.fn_Customer_Status(d.company_id, d.[Sell-to Customer No_],d.[Order Date])))) hash_check --
        from 
            [hs_consolidated].[Sales Header] d
        outer apply
        (
            select top 1
                nullif(pr.[Payment Method Code],'') [Payment Method Code]
            from
                hs_consolidated.[Payment_Refund] pr
            where
                (
                    pr.company_id = d.company_id
                and pr.[Buying Reference No_] = d.[External Document No_]
                )
            order by
                [Collected Amount (LCY)] desc
        ) pm
        where
            (
                [Order Date] >= datefromparts(year(getdate())-2,1,1) 
            )

        union all

        select 
            d.company_id,
            d.[No_],
            d.[Document Type],
            d.[Sell-to Customer No_],
            d.[Order Date],
            d.[Ship-to Country_Region Code],
            d.[Channel Code],
            nullif(d.[Media Code],'') [Media Code],
            isnull(pm.[Payment Method Code],d.[Payment Method Code]) [Payment Method Code],
            ext.fn_Convert_CurrencyFactor_GBP(d.[Currency Factor],d.company_id,d.[Order Date]) [Currency Factor],
            ext.fn_Customer_Status(d.company_id, d.[Sell-to Customer No_],d.[Order Date]) customer_status,
            nullif(d.[Inbound Integration Code],'') [Inbound Integration Code],
            d.[Origin Datetime],
            d.[Order Created DateTime],
            d.[Sales Order Status] [Sales Order Status], --
            d.[Status],
            nullif(d.[On Hold],'') [On Hold],
            checksum(d.[Sell-to Customer No_],d.[Order Date],d.[Ship-to Country_Region Code],d.[Channel Code],d.[Media Code],isnull(pm.[Payment Method Code],d.[Payment Method Code]),d.[Currency Factor],nullif(d.[Inbound Integration Code],''),d.[Origin Datetime],d.[Order Created DateTime],d.[Sales Order Status],d.[Status],nullif(d.[On Hold],''),d.[Order Created by],d.[Subscription No_],db_sys.fn_outcode(d.[Ship-to Post Code],d.[Ship-to Country_Region Code]),ext.fn_Customer_Status(d.company_id, d.[Sell-to Customer No_],d.[Order Date])) dbo_checksum,
            isnull(nullif(d.[External Document No_],''),d.No_) [External Document No_],
            (select ID from db_sys.Users where Users.ad_id = d.[Order Created by]) [Created By ID], /**/
            nullif(d.[Subscription No_],'') [Subscription No_],
            db_sys.fn_outcode(d.[Ship-to Post Code],d.[Ship-to Country_Region Code]) outcode_id,
            convert(varbinary(16),hashbytes('MD5',concat(d.[Sell-to Customer No_],d.[Order Date],d.[Ship-to Country_Region Code],d.[Channel Code],d.[Media Code],isnull(pm.[Payment Method Code],d.[Payment Method Code]),d.[Currency Factor],nullif(d.[Inbound Integration Code],''),d.[Origin Datetime],d.[Order Created DateTime],d.[Sales Order Status],d.[Status],nullif(d.[On Hold],''),d.[Order Created by],d.[Subscription No_],db_sys.fn_outcode(d.[Ship-to Post Code],d.[Ship-to Country_Region Code]),ext.fn_Customer_Status(d.company_id, d.[Sell-to Customer No_],d.[Order Date])))) hash_check --
        from 
            [hs_consolidated].[Sales Header Archive] d
        join
            stg.Sales_Header_Archive s
        on
            (
                s.company_id = d.company_id
            and s.[Document Type] = d.[Document Type] 
            and s.[No_] = d.[No_] 
            and s.[Doc_ No_ Occurrence] = d.[Doc_ No_ Occurrence] 
            and s.[Version No_] = d.[Version No_]
            )
        outer apply
            (
                select top 1
                    nullif(pr.[Payment Method Code],'') [Payment Method Code]
                from
                    hs_consolidated.[Payment_Refund] pr
                where
                    (
                        pr.company_id = d.company_id
                    and pr.[Buying Reference No_] = d.[External Document No_]
                    )
                order by
                    [Collected Amount (LCY)] desc
            ) pm
        where
            (
                s.place_holder is null
            and d.[Archive Reason] = 3
            and not exists (select 1 from ext.Sales_Header where Sales_Header.company_id = d.company_id and Sales_Header.[Document Type] = d.[Document Type] and Sales_Header.No_ = d.No_)
            and not exists (select 1 from hs_consolidated.[Sales Header] where [Sales Header].company_id = d.company_id and [Sales Header].[Document Type] = d.[Document Type] and [Sales Header].No_ = d.No_)
            )
    ) s
on
    (
        t.company_id = s.company_id
    and t.No_ = s.No_
    and t.[Document Type] = s.[Document Type]
    )
when not matched by target then
    insert (company_id, [No_],[Document Type],[Sell-to Customer No_],[Order Date],[Ship-to Country_Region Code],[Channel Code],[Media Code],[Payment Method Code],[Currency Factor],customer_status,[Inbound Integration Code],[Origin Datetime],[Created DateTime],[Sales Order Status],[Status],[On Hold],dbo_checksum, [External Document No_], [Created By ID], [Subscription No_], outcode_id, hash_check)
    values (s.company_id, s.[No_],s.[Document Type],s.[Sell-to Customer No_],s.[Order Date],s.[Ship-to Country_Region Code],s.[Channel Code],s.[Media Code],s.[Payment Method Code],s.[Currency Factor],s.customer_status,s.[Inbound Integration Code],s.[Origin Datetime],s.[Created DateTime],s.[Sales Order Status],s.[Status],s.[On Hold],s.dbo_checksum, s.[External Document No_], s.[Created By ID], s.[Subscription No_], s.outcode_id, s.hash_check)
when matched and isnull(t.dbo_checksum,0) != s.dbo_checksum then update set
    t.[Sell-to Customer No_] = s.[Sell-to Customer No_],
    t.[Order Date] = s.[Order Date],
    t.[Ship-to Country_Region Code] = s.[Ship-to Country_Region Code],
    t.[Channel Code] = s.[Channel Code],
    t.[Media Code] = s.[Media Code],
    t.[Payment Method Code] = s.[Payment Method Code],
    t.[Currency Factor] = s.[Currency Factor],
    t.customer_status = s.customer_status,
    t.[Inbound Integration Code] = s.[Inbound Integration Code],
    t.[Origin Datetime] = s.[Origin Datetime],
    t.[Created DateTime] = s.[Created DateTime],
    t.[Sales Order Status] = s.[Sales Order Status],
    t.[Status] = s.[Status],
    t.[On Hold] = s.[On Hold],
    t.dbo_checksum = s.dbo_checksum,
    t.[External Document No_] = s.[External Document No_],
    t.[Created By ID] = s.[Created By ID],
    t.[Subscription No_] = s.[Subscription No_],
    t.outcode_id = s.outcode_id,
    t.hash_check = s.hash_check;

update ext.Sales_Header set id = next value for ext.sq_sales_header where id is null --

--sales line
merge ext.Sales_Line t
using
    (
        select
            d.company_id,
            d.[Document Type],
            d.[Document No_],
            d.[Line No_],
            d.[Location Code],
            d.[No_],d.[Quantity],
            ext.fn_Convert_Currency_GBP(d.[Promotion Discount Amount],d.company_id,h.[Order Date]) [Promotion Discount Amount],
            ext.fn_Convert_Currency_GBP(d.[Line Discount Amount],d.company_id,h.[Order Date]) [Line Discount Amount],
            ext.fn_Convert_Currency_GBP(d.[Amount Including VAT],d.company_id,h.[Order Date]) [Amount Including VAT],
            ext.fn_Convert_Currency_GBP(d.[Amount],d.company_id,h.[Order Date]) [Amount],
            d.[Dimension Set ID],
            nullif(d.[Delivery Service],'') [Delivery Service],
            d.[Quantity Shipped],
            d.[Quantity Invoiced],
            d.[Outstanding Quantity],
            d.[Type],
            nullif(d.[BOM Item No_],'') [BOM Item No_],
            checksum(d.[Location Code],d.[No_],[Quantity],d.[Promotion Discount Amount],d.[Line Discount Amount],d.[Amount Including VAT],d.[Amount],d.[Dimension Set ID],nullif(d.[Delivery Service],''),d.[Quantity Shipped],d.[Quantity Invoiced],d.[Outstanding Quantity],d.[Type],d.[BOM Item No_]) dbo_checksum,
            convert(varbinary(16),hashbytes('MD5',concat(d.[Location Code],d.[No_],[Quantity],d.[Promotion Discount Amount],d.[Line Discount Amount],d.[Amount Including VAT],d.[Amount],d.[Dimension Set ID],nullif(d.[Delivery Service],''),d.[Quantity Shipped],d.[Quantity Invoiced],d.[Outstanding Quantity],d.[Type],d.[BOM Item No_]))) hash_check --
        from
            [hs_consolidated].[Sales Line] d
        join
            ext.Sales_Header h
        on
            (
                d.company_id = h.company_id
            and d.[Document Type] = h.[Document Type] 
            and d.[Document No_] = h.No_
            )

        union all

        select
            d.company_id,
            d.[Document Type],
            d.[Document No_],
            d.[Line No_],
            d.[Location Code],
            d.[No_],d.[Quantity],
            ext.fn_Convert_Currency_GBP(d.[Promotion Discount Amount],d.company_id,h.[Order Date]) [Promotion Discount Amount],
            ext.fn_Convert_Currency_GBP(d.[Line Discount Amount],d.company_id,h.[Order Date]) [Line Discount Amount],
            ext.fn_Convert_Currency_GBP(d.[Amount Including VAT],d.company_id,h.[Order Date]) [Amount Including VAT],
            ext.fn_Convert_Currency_GBP(d.[Amount],d.company_id,h.[Order Date]) [Amount],
            d.[Dimension Set ID],
            nullif(d.[Delivery Service],'') [Delivery Service],
            d.[Quantity Shipped],
            d.[Quantity Invoiced],
            d.[Outstanding Quantity],
            d.[Type],
            nullif(d.[BOM Item No_],'') [BOM Item No_],
            checksum(d.[Location Code],d.[No_],[Quantity],d.[Promotion Discount Amount],d.[Line Discount Amount],d.[Amount Including VAT],d.[Amount],d.[Dimension Set ID],nullif(d.[Delivery Service],''),d.[Quantity Shipped],d.[Quantity Invoiced],d.[Outstanding Quantity],d.[Type],d.[BOM Item No_]) dbo_checksum,
            convert(varbinary(16),hashbytes('MD5',concat(d.[Location Code],d.[No_],[Quantity],d.[Promotion Discount Amount],d.[Line Discount Amount],d.[Amount Including VAT],d.[Amount],d.[Dimension Set ID],nullif(d.[Delivery Service],''),d.[Quantity Shipped],d.[Quantity Invoiced],d.[Outstanding Quantity],d.[Type],d.[BOM Item No_]))) hash_check --
        from
            [hs_consolidated].[Sales Line Archive] d
        join
            stg.Sales_Line_Archive s
        on
            (
                s.company_id = d.company_id
            and s.[Document Type] = d.[Document Type] 
            and s.[Document No_] = d.[Document No_] 
            and s.[Doc_ No_ Occurrence] = d.[Doc_ No_ Occurrence] 
            and s.[Version No_] = d.[Version No_]
            and s.[Line No_] = d.[Line No_]
            )
        join
            hs_consolidated.[Sales Header Archive] h
        on
            (
                d.company_id = h.company_id
            and d.[Document Type] = h.[Document Type] 
            and d.[Document No_] = h.[No_]
            and d.[Doc_ No_ Occurrence] = h.[Doc_ No_ Occurrence] 
            and d.[Version No_] = h.[Version No_]
            )
        where
            (
                s.place_holder is null
            and h.[Archive Reason] = 3
            and not exists (select 1 from ext.Sales_Line where d.company_id = Sales_Line.company_id and d.[Document Type] = Sales_Line.[Document Type] and d.[Document No_] = Sales_Line.[Document No_] and d.[Line No_] = Sales_Line.[Line No_])
            and not exists (select 1 from hs_consolidated.[Sales Line] where d.company_id = [Sales Line].company_id and d.[Document Type] = [Sales Line].[Document Type] and d.[Document No_] = [Sales Line].[Document No_] and d.[Line No_] = [Sales Line].[Line No_])
            )
    ) s
on
    (
        t.company_id = s.company_id
    and t.[Document Type] = s.[Document Type]
    and t.[Document No_] = s.[Document No_]
    and t.[Line No_] = s.[Line No_]
    )
when not matched by target then
insert (company_id, [Document Type],[Document No_],[Line No_],[Location Code],[No_],[Quantity],[Promotion Discount Amount],[Line Discount Amount],[Amount Including VAT],[Amount],[Dimension Set ID],[Delivery Service],[Quantity Shipped],[Quantity Invoiced],[Outstanding Quantity],[Type],dbo_checksum,hash_check)
values (s.company_id, s.[Document Type],s.[Document No_],s.[Line No_],s.[Location Code],s.[No_],s.[Quantity],s.[Promotion Discount Amount],s.[Line Discount Amount],s.[Amount Including VAT],s.[Amount],s.[Dimension Set ID],s.[Delivery Service],s.[Quantity Shipped],s.[Quantity Invoiced],s.[Outstanding Quantity],s.[Type],s.dbo_checksum,s.hash_check)
when matched and isnull(t.dbo_checksum,0) != s.dbo_checksum then update set
    t.[Location Code] = s.[Location Code],
    t.[No_] = s.[No_],
    t.[Quantity] = s.[Quantity],
    t.[Promotion Discount Amount] = s.[Promotion Discount Amount],
    t.[Line Discount Amount] = s.[Line Discount Amount],
    t.[Amount Including VAT] = s.[Amount Including VAT],
    t.[Amount] = s.[Amount],
    t.[Dimension Set ID] = s.[Dimension Set ID],
    t.[Delivery Service] = s.[Delivery Service],
    t.[Quantity Shipped] = s.[Quantity Shipped],
    t.[Quantity Invoiced] = s.[Quantity Invoiced],
    t.[Outstanding Quantity] = s.[Outstanding Quantity],
    t.[Type] = s.[Type],
    t.[BOM Item No_] = s.[BOM Item No_],
    t.dbo_checksum = s.dbo_checksum,
    t.hash_check = s.hash_check;

-- populate table ext.External_Document_Number
insert into ext.External_Document_Number (company_id, [External Document No_])
select
    company_id,
    [External Document No_]
from
    ext.Sales_Header sh
where
    (
        not exists (select 1 from ext.External_Document_Number edn where sh.company_id = edn.company_id and sh.[External Document No_] = edn.[External Document No_])
    )
group by
    company_id,
    [External Document No_]

insert into ext.External_Document_Number (company_id, [External Document No_])
select distinct
    company_id,
    isnull(nullif([External Document No_],''),No_)
from
    [hs_consolidated].[Return Receipt Header] rrh
where
    (
        not exists (select 1 from ext.External_Document_Number edn where rrh.company_id = edn.company_id and isnull(nullif(rrh.[External Document No_],''),rrh.No_) = edn.[External Document No_])
    )

update ext.Sales_Line set id = next value for ext.sq_sales_line where id is null

update 
    l 
set 
    l.sales_header_id = h.id 
from 
    ext.Sales_Line l 
join 
    ext.Sales_Header h 
on
	(
        h.company_id = l.company_id
    and h.No_ = l.[Document No_]
	and h.[Document Type] = l.[Document Type]
	)
where
    (
        l.sales_header_id is null
    )

-- ***start*** Remove deleted sales from Sales_Header and Sales_Line as soon as they are flagged as deleted/removed in the archive
insert into ext.Sales_Delete (company_id, [Document Type], [No_], auditLog_ID)
select 
    company_id,
    [Document Type], 
    [No_], 
    isnull(@auditLog_ID,-1)
from 
    ext.Sales_Header 
where 
    (
        exists (select 1 from [hs_consolidated].[Sales Header Archive] Sales_Header_Archive where Sales_Header.company_id = Sales_Header_Archive.company_id and Sales_Header.[Document Type] = Sales_Header_Archive.[Document Type] and Sales_Header.No_ = Sales_Header_Archive.No_ and Sales_Header_Archive.[Archive Reason] = 1)
    and not exists (select 1 from ext.Sales_Delete where Sales_Header.company_id = Sales_Delete.company_id and Sales_Header.[Document Type] = Sales_Delete.[Document Type] and Sales_Header.No_ = Sales_Delete.No_)
    )

insert into ext.Sales_Delete (company_id, [Document Type], [No_], auditLog_ID)
select 
    company_id,
    [Document Type], 
    [No_], 
    isnull(@auditLog_ID,-1)
from 
    ext.Sales_Header 
where 
    (
        (
            exists (select 1 from [hs_consolidated].[Sales Header Archive] Sales_Header_Archive where Sales_Header.company_id = Sales_Header_Archive.company_id and Sales_Header.[Document Type] = Sales_Header_Archive.[Document Type] and Sales_Header.No_ = Sales_Header_Archive.No_ and Sales_Header_Archive.[Archive Reason] = 1)
        )
    and not exists (select 1 from ext.Sales_Delete where Sales_Header.company_id = Sales_Delete.company_id and Sales_Header.[Document Type] = Sales_Delete.[Document Type] and Sales_Header.No_ = Sales_Delete.No_)
    )

delete from ext.Sales_Header where exists (select 1 from ext.Sales_Delete where Sales_Header.company_id = Sales_Delete.company_id and Sales_Header.[Document Type] = Sales_Delete.[Document Type] and Sales_Header.No_ = Sales_Delete.No_)

delete from ext.Sales_Line where exists (select 1 from ext.Sales_Delete where Sales_Line.company_id = Sales_Delete.company_id and Sales_Line.[Document Type] = Sales_Delete.[Document Type] and Sales_Line.[Document No_] = Sales_Delete.No_)

-- ***end***
GO