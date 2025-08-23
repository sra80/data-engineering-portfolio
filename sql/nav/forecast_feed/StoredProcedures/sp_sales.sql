create or alter procedure [forecast_feed].[sp_sales]
    (
        @run_id uniqueidentifier = null,
        @recomp_year_week int = null,
        @is_test bit = 0
    )

as

set nocount on

declare @cal table (d_from date, d_to date)

declare @list table (key_date int)

declare 
    @procedureName nvarchar(64) = 'forecast_feed.sp_sales',
    @place_holder uniqueidentifier = newid(),
    @auditLog_ID int,
    @parent_auditLog_ID int,
    @eventDetail nvarchar(64),
    @d_from date,
    @d_to date,
    @d_yw int,
    @count int,
    @bodyIntro nvarchar(max) = 'The update to Anaplan sales is complete, changes were made to ',
    @changes_outOfScope bit = 0,
    @key_date int,
    @recomp_year_week_os bit = 0 --@recomp_year_week out of scope

if @recomp_year_week is not null or @is_test = 1

    begin /*4e98*/

        set @procedureName = concat(@procedureName,' (recompile ',@recomp_year_week,')')

        set @bodyIntro = concat('Anaplan sales for period ',@recomp_year_week,' have been successfully recompiled.')

        insert into @cal (d_from, d_to)
        select 
            db_sys.fn_datefrom_year_week(sq.key_date/100, sq.key_date%100, 1),
            db_sys.fn_datefrom_year_week(sq.key_date/100, sq.key_date%100, 7)
        from 
            (
                select
                    @recomp_year_week key_date
            ) sq
        where
            (
                sq.key_date > 0
            )

        if (select top 1 d_from from @cal) between datefromparts(year(getutcdate())-3,1,1) and getutcdate()

            begin /*c525*/
        
                delete from forecast_feed.sales where key_date = @recomp_year_week

            end /*c525*/

        else

            begin /*b0c7*/

                set @is_test = 1

                set @recomp_year_week_os = 1

                if @recomp_year_week is null
                
                    set @bodyIntro = '@recomp_year_week is null, this parameter must be set to a valid period as yyyyww'

                else

                    set @bodyIntro = concat('Period ',@recomp_year_week,' is out of scope')

                raiserror(@bodyIntro, 0, 0) with nowait

            end /*b0c7*/


    end /*4e98*/

if @is_test = 0 exec db_sys.sp_auditLog_start @eventType = 'Procedure', @eventName = @procedureName, @eventVersion = '00', @placeHolder_ui = @place_holder, @placeHolder_session = @run_id

select @auditLog_ID = ID from db_sys.auditLog where place_holder = @place_holder

select @parent_auditLog_ID = auditLog_ID from db_sys.auditLog_dataFactory where run_ID = @run_id

        if @auditLog_ID > 0 and @parent_auditLog_ID > 0 and (select isnull(sum(1),0) from db_sys.auditLog_procedure_dependents where auditLog_ID = @auditLog_ID) = 0

        insert into db_sys.auditLog_procedure_dependents (parent_auditLog_ID, auditLog_ID)
        values (@parent_auditLog_ID, @auditLog_ID)

begin try

    if @is_test = 0 and @recomp_year_week is null

        begin /*beb2*/

            truncate table stg.anaplan_sales

            truncate table forecast_feed.sales_changes

            delete from forecast_feed.sales where key_date < (year(getutcdate())-3)*100

            insert into stg.anaplan_sales (source, id, key_date)
            select
                0 source,
                l.id,
                datepart(year,h.[Order Date])*100 + datepart(week,h.[Order Date]) key_date
            from
                ext.Sales_Header h
            join
                (
                    select
                        id,
                        sales_header_id,
                        company_id,
                        [Location Code],
                        [Dimension Set ID],
                        [No_],
                        [Quantity]
                    from 
                        ext.Sales_Line
                    where 
                        (
                            company_id = 1 
                        and id not in
                            (
                                select
                                    id
                                from
                                    forecast_feed.sales_trace
                                where 
                                    (
                                        source = 0
                                    )
                            )
                        )
                ) l
            on
                (
                    h.id = l.sales_header_id
                )
            join
                [hs_consolidated].[Customer] cust
            on
                (
                    h.company_id = cust.company_id
                and h.[Sell-to Customer No_] = cust.[No_]
                )
            join
                forecast_feed.location_overide_aggregate loc
            on
                (
                    l.company_id = loc.company_id
                and l.[Location Code] = loc.location_code
                )
            left join
                [forecast_feed].[Dimensions] d
            on
                (
                    d.company_id = l.company_id
                and d.keyDimensionSetID = l.[Dimension Set ID]
                )
            left join
                (
                    select
                        company_id,
                        [No_],
                        [Dimension Value Code]
                    from
                        [hs_consolidated].[Default Dimension] b
                    where
                        (
                            b.[Dimension Code] = 'SALE.CHANNEL'
                        and [Table ID] = 18
                        )
                ) sc
            on
                (
                    sc.company_id = cust.company_id
                and sc.[No_] = cust.[No_]
                )
            cross apply
                (
                    select
                        -min(ID)-1 ID
                    from
                        ext.Customer_Type ct
                    where
                        (
                            cust.[Customer Type] = ct.nav_code
                        )
                ) ct
            cross apply
                (
                    select
                        min(ID) ID
                    from
                        ext.Item i
                    where
                        (
                            l.No_ = i.No_
                        )
                ) i
            where
                (
                    h.[Sales Order Status] = 1
                and h.[Order Date] >= datefromparts(year(getutcdate())-3,1,1)
                )

            insert into stg.anaplan_sales (source, id, key_date)
            select
                1 source,
                l.id,
                datepart(year,h.[Order Date])*100 + datepart(week,h.[Order Date]) key_date
            from
                ext.Sales_Header_Archive h
            join
                (
                    select
                        id,
                        sales_header_id,
                        company_id,
                        [Location Code],
                        [Dimension Set ID],
                        [No_],
                        [Quantity]
                    from 
                        ext.Sales_Line_Archive 
                    where 
                        (
                            company_id = 1 
                        and id not in
                            (
                                select
                                    id
                                from
                                    forecast_feed.sales_trace
                                where 
                                    (
                                        source = 1
                                    )
                            )
                        )
                ) l
            on
                (
                    h.id = l.sales_header_id
                )
            join
                [hs_consolidated].[Customer] cust
            on
                (
                    h.company_id = cust.company_id
                and h.[Sell-to Customer No_] = cust.[No_]
                )
            join
                forecast_feed.location_overide_aggregate loc
            on
                (
                        l.company_id = loc.company_id
                    and l.[Location Code] = loc.location_code
                )
            left join
                [forecast_feed].[Dimensions] d
            on
                (
                    d.company_id = l.company_id
                and d.keyDimensionSetID = l.[Dimension Set ID]
                )
            left join
                (
                    select
                        company_id,
                        [No_],
                        [Dimension Value Code]
                    from
                        [hs_consolidated].[Default Dimension] b
                    where
                        b.[Dimension Code] = 'SALE.CHANNEL'
                    and [Table ID] = 18
                ) sc
            on
                (
                    sc.company_id = cust.company_id
                and sc.[No_] = cust.[No_]
                )
            cross apply
                (
                    select
                        -min(ID)-1 ID
                    from
                        ext.Customer_Type ct
                    where
                        (
                            cust.[Customer Type] = ct.nav_code
                        )
                ) ct
            cross apply
                (
                    select
                        min(ID) ID
                    from
                        ext.Item i
                    where
                        (
                            l.No_ = i.No_
                        )
                ) i
            where
                (
                    h.[Order Date] >= datefromparts(year(getutcdate())-3,1,1)
                )

            insert into stg.anaplan_sales (source, id, key_date)
            select
                2 source,
                ile.[Entry No_] id,
                datepart(year,ile.[Document Date])*100 + datepart(week,ile.[Document Date]) key_date
            from
                [dbo].[UK$Item Ledger Entry] ile
            join
                finance.SalesInvoices_Amazon amz
            on
                (
                    ile.[Location Code] = amz.warehouse
                )
            join
                ext.Location loc
            on
                (
                    loc.company_id = 1
                and ile.[Location Code] = loc.location_code
                )
            join
                ext.Item i
            on
                (
                    i.company_id = 1
                and ile.[Item No_] = i.No_
                )
            join
                [forecast_feed].[Dimensions] d
            on
                (
                    d.company_id = 1
                and d.keyDimensionSetID = ile.[Dimension Set ID]
                )
            where
                (
                    ile.[Entry No_] not in
                        (
                            select
                                id
                            from
                                forecast_feed.sales_trace
                            where
                                (
                                    source = 2
                                )
                        )
                    and ile.[Document Date] >= datefromparts(year(getutcdate())-3,1,1)
                )

            insert into @cal (d_from, d_to)
            select 
                db_sys.fn_datefrom_year_week(sq.key_date/100, sq.key_date%100, 1),
                db_sys.fn_datefrom_year_week(sq.key_date/100, sq.key_date%100, 7)
            from 
                (
                    select distinct 
                        key_date 
                    from
                        stg.anaplan_sales
                ) sq

        end /*beb2*/

    while (select isnull(sum(1),0) from @cal) > 0

        begin /*b195*/

            select top 1 @d_from = d_from, @d_to = d_to, @d_yw = (datepart(year,d_from) * 100) + datepart(week,d_from) from @cal

            if @is_test = 0

                begin /*91f1*/

                    merge 
                        forecast_feed.sales t
                    using
                        (
                            select
                                sales.primary_key,
                                sales.key_date,
                                sales.key_demand_channel,
                                sales.key_customer,
                                sales.key_sales_channel,
                                sales.key_location,
                                sales.key_item,
                                isnull(sales.units,0) units
                            from
                                (
                                    select
                                        concat(sales.key_date,sales.key_platform,sales.key_customer,sales.key_sales_channel,sales.key_location,sales.key_item) primary_key,
                                        sales.key_date,
                                        sales.key_platform key_demand_channel,
                                        sales.key_customer,
                                        sales.key_sales_channel,
                                        sales.key_location,
                                        sales.key_item,
                                        ceiling(sum(sales.units)) units
                                    from
                                        (
                                            select
                                                datepart(year,h.[Order Date])*100 + datepart(week,h.[Order Date]) key_date,
                                                ext.fn_Platform_Grouping(h.company_id,h.[Channel Code],h.No_,h.[Inbound Integration Code],0) key_platform,
                                                forecast_feed.fn_customer_exposure(h.company_id,h.[Sell-to Customer No_]) key_customer,
                                                isnull(nullif(isnull(sc.[Dimension Value Code],d.[Sale Channel Code]),'INT'),'D2C') key_sales_channel,
                                                loc.location_ID_overide key_location,
                                                i.ID key_item,
                                                l.Quantity units
                                            from
                                                ext.Sales_Header h
                                            join
                                                ext.Sales_Line l
                                            on
                                                (
                                                h.company_id = l.company_id
                                                and h.No_ = l.[Document No_]
                                                and h.[Document Type] = l.[Document Type]
                                                )
                                            join
                                                [hs_consolidated].[Customer] cust
                                            on
                                                (
                                                    h.company_id = cust.company_id
                                                and h.[Sell-to Customer No_] = cust.[No_]
                                                )
                                            join
                                                forecast_feed.location_overide_aggregate loc
                                            on
                                                (
                                                    l.company_id = loc.company_id
                                                and l.[Location Code] = loc.location_code
                                                )
                                            left join
                                                [forecast_feed].[Dimensions] d
                                            on
                                                (
                                                    d.company_id = l.company_id
                                                and d.keyDimensionSetID = l.[Dimension Set ID]
                                                )
                                            left join
                                                (
                                                    select
                                                        company_id,
                                                        [No_],
                                                        [Dimension Value Code]
                                                    from
                                                        [hs_consolidated].[Default Dimension] b
                                                    where
                                                        (
                                                            b.[Dimension Code] = 'SALE.CHANNEL'
                                                        and [Table ID] = 18
                                                        )
                                                ) sc
                                            on
                                                (
                                                    sc.company_id = cust.company_id
                                                and sc.[No_] = cust.[No_]
                                                )
                                            cross apply
                                                (
                                                    select
                                                        -min(ID)-1 ID
                                                    from
                                                        ext.Customer_Type ct
                                                    where
                                                        (
                                                            cust.[Customer Type] = ct.nav_code
                                                        )
                                                ) ct
                                            cross apply
                                                (
                                                    select
                                                        min(ID) ID
                                                    from
                                                        ext.Item i
                                                    where
                                                        (
                                                            l.No_ = i.No_
                                                        )
                                                ) i
                                            where
                                                (
                                                    h.[Order Date] >= @d_from
                                                and h.[Order Date] <= @d_to
                                                )
                                            

                                            union all

                                            select
                                                datepart(year,h.[Order Date])*100 + datepart(week,h.[Order Date]) key_date,
                                                ext.fn_Platform_Grouping(h.company_id,h.[Channel Code],h.No_,h.[Inbound Integration Code],0) key_platform,
                                                forecast_feed.fn_customer_exposure(h.company_id,h.[Sell-to Customer No_]) key_customer,
                                                isnull(nullif(isnull(sc.[Dimension Value Code],d.[Sale Channel Code]),'INT'),'D2C') key_sales_channel,
                                                loc.location_ID_overide key_location,
                                                i.ID key_item,
                                                l.Quantity units
                                            from
                                                ext.Sales_Header_Archive h
                                            join
                                                ext.Sales_Line_Archive l
                                            on
                                                (
                                                    h.company_id = l.company_id
                                                and h.No_ = l.[Document No_]
                                                and h.[Document Type] = l.[Document Type]
                                                and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
                                                and h.[Version No_] = l.[Version No_]
                                                )
                                            join
                                                [hs_consolidated].[Customer] cust
                                            on
                                                (
                                                    h.company_id = cust.company_id
                                                and h.[Sell-to Customer No_] = cust.[No_]
                                                )
                                            join
                                                forecast_feed.location_overide_aggregate loc
                                            on
                                                (
                                                        l.company_id = loc.company_id
                                                    and l.[Location Code] = loc.location_code
                                                )
                                            left join
                                                [forecast_feed].[Dimensions] d
                                            on
                                                (
                                                    d.company_id = l.company_id
                                                and d.keyDimensionSetID = l.[Dimension Set ID]
                                                )
                                            left join
                                                (
                                                    select
                                                        company_id,
                                                        [No_],
                                                        [Dimension Value Code]
                                                    from
                                                        [hs_consolidated].[Default Dimension] b
                                                    where
                                                        b.[Dimension Code] = 'SALE.CHANNEL'
                                                    and [Table ID] = 18
                                                ) sc
                                            on
                                                (
                                                    sc.company_id = cust.company_id
                                                and sc.[No_] = cust.[No_]
                                                )
                                            cross apply
                                                (
                                                    select
                                                        -min(ID)-1 ID
                                                    from
                                                        ext.Customer_Type ct
                                                    where
                                                        (
                                                            cust.[Customer Type] = ct.nav_code
                                                        )
                                                ) ct
                                            cross apply
                                                (
                                                    select
                                                        min(ID) ID
                                                    from
                                                        ext.Item i
                                                    where
                                                        (
                                                            l.No_ = i.No_
                                                        )
                                                ) i
                                            where
                                                (
                                                    h.[Order Date] >= @d_from
                                                and h.[Order Date] <= @d_to
                                                )

                                            union all

                                            select
                                                datepart(year,ile.[Document Date])*100 + datepart(week,ile.[Document Date]) key_date,
                                                (select Group_ID from ext.Platform where ID = amz.platformID) key_platform,
                                                forecast_feed.fn_customer_exposure(1,amz.cus_code) key_customer,
                                                isnull(d.[Sale Channel Code],'MPP') key_sales_channel,
                                                loc.ID key_location,
                                                i.ID key_item,
                                                -ile.Quantity units
                                            from
                                                [dbo].[UK$Item Ledger Entry] ile
                                            join
                                                finance.SalesInvoices_Amazon amz
                                            on
                                                (
                                                    ile.[Location Code] = amz.warehouse
                                                )
                                            join
                                                ext.Location loc
                                            on
                                                (
                                                    loc.company_id = 1
                                                and ile.[Location Code] = loc.location_code
                                                )
                                            join
                                                ext.Item i
                                            on
                                                (
                                                    i.company_id = 1
                                                and ile.[Item No_] = i.No_
                                                )
                                            join
                                                [forecast_feed].[Dimensions] d
                                            on
                                                (
                                                    d.company_id = 1
                                                and d.keyDimensionSetID = ile.[Dimension Set ID]
                                                )
                                            where
                                                (
                                                    ile.[Document Date] >= @d_from
                                                and ile.[Document Date] <= @d_to
                                                )
                                        ) sales
                                    where
                                        (
                                            sales.key_customer > -9999
                                        )
                                    group by
                                            sales.key_date,
                                            sales.key_platform,
                                            sales.key_customer,
                                            sales.key_sales_channel,
                                            sales.key_location,
                                            sales.key_item
                                ) sales
                        ) s
                    on
                        (
                            t.key_date = s.key_date
                        and t.key_demand_channel = s.key_demand_channel
                        and t.key_customer = s.key_customer
                        and t.key_sales_channel = s.key_sales_channel
                        and t.key_location = s.key_location
                        and t.key_item = s.key_item
                        )
                    when not matched by target then
                        insert (primary_key, key_date, key_demand_channel, key_customer, key_sales_channel, key_location, key_item, units, units_adj, auditLog_ID_insert, auditLog_ID_update)
                        values (s.primary_key, s.key_date, s.key_demand_channel, s.key_customer, s.key_sales_channel, s.key_location, s.key_item, s.units, s.units, @auditLog_ID, @auditLog_ID)
                    when matched and t.units != s.units then update set
                        t.units = s.units,
                        t.units_adj = s.units - t.units,
                        t.auditLog_ID_update = @auditLog_ID
                    when not matched by source and t.key_date = @d_yw then update set
                        t.units = 0,
                        t.units_adj = -t.units,
                        t.auditLog_ID_update = @auditLog_ID;

                end /*91f1*/
            
            else

                if @recomp_year_week_os = 0

                    select
                        sales.primary_key,
                        sales.key_date,
                        sales.key_demand_channel,
                        sales.key_customer,
                        sales.key_sales_channel,
                        sales.key_location,
                        sales.key_item,
                        isnull(sales.units,0)
                    from
                        (
                            select
                                concat(sales.key_date,sales.key_platform,sales.key_customer,sales.key_sales_channel,sales.key_location,sales.key_item) primary_key,
                                sales.key_date,
                                sales.key_platform key_demand_channel,
                                sales.key_customer,
                                sales.key_sales_channel,
                                sales.key_location,
                                sales.key_item,
                                ceiling(sum(sales.units)) units
                            from
                                (
                                    select
                                        datepart(year,h.[Order Date])*100 + datepart(week,h.[Order Date]) key_date,
                                        ext.fn_Platform_Grouping(h.company_id,h.[Channel Code],h.No_,h.[Inbound Integration Code],0) key_platform,
                                        forecast_feed.fn_customer_exposure(h.company_id,h.[Sell-to Customer No_]) key_customer,
                                        isnull(nullif(isnull(sc.[Dimension Value Code],d.[Sale Channel Code]),'INT'),'D2C') key_sales_channel,
                                        loc.location_ID_overide key_location,
                                        i.ID key_item,
                                        l.Quantity units
                                    from
                                        ext.Sales_Header h
                                    join
                                        ext.Sales_Line l
                                    on
                                        (
                                        h.company_id = l.company_id
                                        and h.No_ = l.[Document No_]
                                        and h.[Document Type] = l.[Document Type]
                                        )
                                    join
                                        [hs_consolidated].[Customer] cust
                                    on
                                        (
                                            h.company_id = cust.company_id
                                        and h.[Sell-to Customer No_] = cust.[No_]
                                        )
                                    join
                                        forecast_feed.location_overide_aggregate loc
                                    on
                                        (
                                            l.company_id = loc.company_id
                                        and l.[Location Code] = loc.location_code
                                        )
                                    left join
                                        [forecast_feed].[Dimensions] d
                                    on
                                        (
                                            d.company_id = l.company_id
                                        and d.keyDimensionSetID = l.[Dimension Set ID]
                                        )
                                    left join
                                        (
                                            select
                                                company_id,
                                                [No_],
                                                [Dimension Value Code]
                                            from
                                                [hs_consolidated].[Default Dimension] b
                                            where
                                                (
                                                    b.[Dimension Code] = 'SALE.CHANNEL'
                                                and [Table ID] = 18
                                                )
                                        ) sc
                                    on
                                        (
                                            sc.company_id = cust.company_id
                                        and sc.[No_] = cust.[No_]
                                        )
                                    cross apply
                                        (
                                            select
                                                -min(ID)-1 ID
                                            from
                                                ext.Customer_Type ct
                                            where
                                                (
                                                    cust.[Customer Type] = ct.nav_code
                                                )
                                        ) ct
                                    cross apply
                                        (
                                            select
                                                min(ID) ID
                                            from
                                                ext.Item i
                                            where
                                                (
                                                    l.No_ = i.No_
                                                )
                                        ) i
                                    where
                                        (
                                            h.[Order Date] >= @d_from
                                        and h.[Order Date] <= @d_to
                                        )
                                    

                                    union all

                                    select
                                        datepart(year,h.[Order Date])*100 + datepart(week,h.[Order Date]) key_date,
                                        ext.fn_Platform_Grouping(h.company_id,h.[Channel Code],h.No_,h.[Inbound Integration Code],0) key_platform,
                                        forecast_feed.fn_customer_exposure(h.company_id,h.[Sell-to Customer No_]) key_customer,
                                        isnull(nullif(isnull(sc.[Dimension Value Code],d.[Sale Channel Code]),'INT'),'D2C') key_sales_channel,
                                        loc.location_ID_overide key_location,
                                        i.ID key_item,
                                        l.Quantity units
                                    from
                                        ext.Sales_Header_Archive h
                                    join
                                        ext.Sales_Line_Archive l
                                    on
                                        (
                                            h.company_id = l.company_id
                                        and h.No_ = l.[Document No_]
                                        and h.[Document Type] = l.[Document Type]
                                        and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
                                        and h.[Version No_] = l.[Version No_]
                                        )
                                    join
                                        [hs_consolidated].[Customer] cust
                                    on
                                        (
                                            h.company_id = cust.company_id
                                        and h.[Sell-to Customer No_] = cust.[No_]
                                        )
                                    join
                                        forecast_feed.location_overide_aggregate loc
                                    on
                                        (
                                                l.company_id = loc.company_id
                                            and l.[Location Code] = loc.location_code
                                        )
                                    left join
                                        [forecast_feed].[Dimensions] d
                                    on
                                        (
                                            d.company_id = l.company_id
                                        and d.keyDimensionSetID = l.[Dimension Set ID]
                                        )
                                    left join
                                        (
                                            select
                                                company_id,
                                                [No_],
                                                [Dimension Value Code]
                                            from
                                                [hs_consolidated].[Default Dimension] b
                                            where
                                                b.[Dimension Code] = 'SALE.CHANNEL'
                                            and [Table ID] = 18
                                        ) sc
                                    on
                                        (
                                            sc.company_id = cust.company_id
                                        and sc.[No_] = cust.[No_]
                                        )
                                    cross apply
                                        (
                                            select
                                                -min(ID)-1 ID
                                            from
                                                ext.Customer_Type ct
                                            where
                                                (
                                                    cust.[Customer Type] = ct.nav_code
                                                )
                                        ) ct
                                    cross apply
                                        (
                                            select
                                                min(ID) ID
                                            from
                                                ext.Item i
                                            where
                                                (
                                                    l.No_ = i.No_
                                                )
                                        ) i
                                    where
                                        (
                                            h.[Order Date] >= @d_from
                                        and h.[Order Date] <= @d_to
                                        )

                                    union all

                                    select
                                        datepart(year,ile.[Document Date])*100 + datepart(week,ile.[Document Date]) key_date,
                                        (select Group_ID from ext.Platform where ID = amz.platformID) key_platform,
                                        forecast_feed.fn_customer_exposure(1,amz.cus_code) key_customer,
                                        isnull(d.[Sale Channel Code],'MPP') key_sales_channel,
                                        loc.ID key_location,
                                        i.ID key_item,
                                        -ile.Quantity units
                                    from
                                        [dbo].[UK$Item Ledger Entry] ile
                                    join
                                        finance.SalesInvoices_Amazon amz
                                    on
                                        (
                                            ile.[Location Code] = amz.warehouse
                                        )
                                    join
                                        ext.Location loc
                                    on
                                        (
                                            loc.company_id = 1
                                        and ile.[Location Code] = loc.location_code
                                        )
                                    join
                                        ext.Item i
                                    on
                                        (
                                            i.company_id = 1
                                        and ile.[Item No_] = i.No_
                                        )
                                    join
                                        [forecast_feed].[Dimensions] d
                                    on
                                        (
                                            d.company_id = 1
                                        and d.keyDimensionSetID = ile.[Dimension Set ID]
                                        )
                                    where
                                        (
                                            ile.[Document Date] >= @d_from
                                        and ile.[Document Date] <= @d_to
                                        )
                                ) sales
                            group by
                                    sales.key_date,
                                    sales.key_platform,
                                    sales.key_customer,
                                    sales.key_sales_channel,
                                    sales.key_location,
                                    sales.key_item
                        ) sales

            delete from @cal where d_from = @d_from

        end /*b195*/

if @is_test = 0 and @recomp_year_week is null

    begin /*8a5b*/

        insert into forecast_feed.sales_changes (key_date, key_demand_channel, key_customer, key_sales_channel, key_location, key_item, units)
        select
            key_date, key_demand_channel, key_customer, key_sales_channel, key_location, key_item, units_adj
        from
            forecast_feed.sales
        where
            (
                sales.auditLog_ID_update = @auditLog_ID
            and key_date <
                (
                    select 
                        (datepart(year,d.d) * 100) + datepart(week,d.d)
                    from
                        (
                            select
                                dateadd(week,-2,getutcdate()) d
                        ) d
                )
            )

        insert into forecast_feed.sales_trace (source, id, auditLog_ID)
        select
            source,
            id,
            @auditLog_ID
        from
            stg.anaplan_sales

        --cleanup forecast_feed.sales_trace
        delete from
            t
        from
            forecast_feed.sales_trace t
        left join
            (
                select
                    l.id,
                    h.[Order Date]
                from
                    ext.Sales_Line l
                join
                    ext.Sales_Header h
                on
                    (
                        l.sales_header_id = h.id
                    )
            ) s
        on
            (
                t.id = s.id
            )
        where
            (
                t.source = 0
            and
                (
                    s.id is null
                or  s.[Order Date] < datefromparts(year(getutcdate())-3,1,1)
                )
            )

        delete from
            t
        from
            forecast_feed.sales_trace t
        left join
            (
                select
                    l.id,
                    h.[Order Date]
                from
                    ext.Sales_Line_Archive l
                join
                    ext.Sales_Header_Archive h
                on
                    (
                        l.sales_header_id = h.id
                    )
            ) s
        on
            (
                t.id = s.id
            )
        where
            (
                t.source = 1
            and
                (
                    s.id is null
                or  s.[Order Date] < datefromparts(year(getutcdate())-3,1,1)
                )
            )

        delete from
            t
        from
            forecast_feed.sales_trace t
        left join
            (
                select
                    ile.[Entry No_],
                    ile.[Document Date]
                from
                    [dbo].[UK$Item Ledger Entry] ile
            ) s
        on
            (
                t.id = s.[Entry No_]
            )
        where
            (
                t.source = 2
            and
                (
                    s.[Entry No_] is null
                or  s.[Document Date] < datefromparts(year(getutcdate())-3,1,1)
                )
            )

    end /*8a5b*/

    --issue status update in Teams - General channel

    if @is_test = 0

        begin /*3a35*/

            if @recomp_year_week is null

                insert into @list (key_date)
                select distinct
                    key_date
                from
                    stg.anaplan_sales

            else

                insert into @list (key_date)
                values (@recomp_year_week)

            select @count = isnull(sum(1),0), @key_date = min(key_date) from @list

            if datediff(week,db_sys.fn_datefrom_year_week(@key_date/100,@key_date%100,1),getutcdate()) > 2
            
                begin /*13a6*/
                
                    set @changes_outOfScope = 1

                end /*13a6*/

            if @recomp_year_week is null and @count = 1

                begin /*85bd*/

                set @bodyIntro += 'week '

                if @key_date/100 = year(getutcdate()) set @bodyIntro += @key_date%100 else set @bodyIntro += concat(@key_date%100,' of ',@key_date/100)

                set @bodyIntro += '.'

                end /*85bd*/

            if @recomp_year_week is null and @count > 1

                begin /*4b74*/

                set @bodyIntro += 'the following periods:<ul>'

                    if (select min(key_date/100) from @list) = year(getutcdate()) and (select max(key_date/100) from @list) = year(getutcdate())

                        select @bodyIntro += concat('<li>Week ',key_date%100,'</li>') from @list order by key_date
                    
                    else
                        
                        select @bodyIntro += concat('<li>Week ',key_date%100,' (',key_date/100,')</li>') from @list order by key_date

                select @bodyIntro += '</ul>'

                end /*4b74*/

            if @count > 0

                begin /*423f*/

                    if @changes_outOfScope = 0

                        begin /*42e7*/

                            exec db_sys.sp_email_notifications
                                    @subject = 'Anaplan Sales Transaction Status Update',
                                    @bodyIntro = @bodyIntro,
                                    @auditLog_ID = @auditLog_ID,
                                    @is_team_alert = 1,
                                    @tnc_id = 16,
                                    @place_holder = @place_holder

                        end /*42e7*/

                    else if @recomp_year_week is null

                        begin /*592b*/

                            set @bodyIntro = concat(@bodyIntro,'<p><b>Note: </b>Any changes going back further than 2 weeks will not immediately reflect in Anaplan. However, the sales_all.csv file will include all data going back to January ',year(getutcdate())-3,', this file is loaded once a week into Anaplan to backfill sales that were previously not included. The following shows which sales lines have been impacted by changes outside of the 2 week window:')

                            exec db_sys.sp_email_notifications
                                    @subject = 'Anaplan Sales Transaction Status Update',
                                    @bodyIntro = @bodyIntro,
                                    @bodySource = 'forecast_feed.vw_sales_changes',
                                    @auditLog_ID = @auditLog_ID,
                                    @is_team_alert = 1,
                                    @tnc_id = 16,
                                    @place_holder = @place_holder
                        
                        end /*592b*/

                    else

                        begin /*5c09*/

                            set @bodyIntro = concat(@bodyIntro,'<p><b>Note: </b>Any changes going back further than 2 weeks will not immediately reflect in Anaplan. However, the sales_all.csv file will include all data going back to January ',year(getutcdate())-3,', this file is loaded once a week into Anaplan to backfill sales that were previously not included.')

                            exec db_sys.sp_email_notifications
                                    @subject = 'Anaplan Sales Transaction Status Update',
                                    @bodyIntro = @bodyIntro,
                                    @auditLog_ID = @auditLog_ID,
                                    @is_team_alert = 1,
                                    @tnc_id = 16,
                                    @place_holder = @place_holder
                        
                        end /*5c09*/

                    end /*423f*/

        end /*3a35*/

        set @eventDetail = 'Procedure Outcome: Success'

end try

begin catch

    set @eventDetail = 'Procedure Outcome: Failed'

    if @is_test = 0 insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage) values (@procedureName, @auditLog_ID, error_line(), error_message())

    if @is_test = 1 
    
        begin /*470d*/

            declare @error_message nvarchar(max) = error_message(), @error_severity int = error_severity(), @error_state int = error_state()
        
            raiserror(@error_message, @error_severity, @error_state)

        end /*470d*/

end catch

if @is_test = 0 exec db_sys.sp_auditLog_end @eventDetail = @eventDetail, @placeHolder_ui = @place_holder