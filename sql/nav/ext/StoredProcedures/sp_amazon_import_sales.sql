create or alter procedure ext.sp_amazon_import_sales
    (
        @file_body nvarchar(max),
        @filelist_id int,
        @place_holder_session uniqueidentifier,
        @logicApp_ID nvarchar(36),
        @is_test bit = 0
    )

as

set nocount on

declare @place_holder uniqueidentifier = newid(), @eventDetail nvarchar(64), @auditLog_ID int, @error_count int = 0, @report_error bit = 1

if (select top 1 procedureName from db_sys.procedure_schedule where procedureName = 'ext.sp_amazon_import_sales') is null insert into db_sys.procedure_schedule (procedureName, place_holder, place_holder_session) values ('ext.sp_amazon_import_sales', @place_holder, @place_holder_session)

if @is_test = 0 and (select place_holder_session from db_sys.procedure_schedule where procedureName = 'ext.sp_amazon_import_sales') != @place_holder_session update db_sys.procedure_schedule set place_holder = @place_holder, place_holder_session = @place_holder_session, error_count = 0 where procedureName = 'ext.sp_amazon_import_sales'

select @error_count = error_count from db_sys.procedure_schedule where procedureName = 'ext.sp_amazon_import_sales'

if @is_test = 0 exec db_sys.sp_auditLog_start @eventType = 'Procedure',@eventName='ext.sp_amazon_import_sales',@eventVersion='00',@placeHolder_ui=@place_holder,@placeHolder_session=@place_holder_session,@logicApp_ID=@logicApp_ID

select @auditLog_ID = ID from db_sys.auditLog where place_holder = @place_holder

begin try

    declare @t table
        (
            [amazon_order_id_p1] int,
            [amazon_order_id_p2] int,
            [amazon_order_id_p3] int,
            [merchant_order_id]  nvarchar(32),
            [shipment_id] nvarchar(32),
            [line] int,
            [purchase_date] datetime2(0),
            [payments_date] datetime2(0),
            [shipment_date] datetime2(0),
            [reporting_date] datetime2(0),
            [currency] nvarchar(32),
            [ship_service_level] nvarchar(32),
            [ship_city] nvarchar(32),
            [ship_state] nvarchar(32),
            [ship_postal_code] nvarchar(32),
            [ship_country] nvarchar(32),
            [carrier] nvarchar(32),
            [estimated_arrival_date] date,
            [fulfillment_center_id] nvarchar(32),
            [fulfillment_channel] nvarchar(32),
            [sales_channel] nvarchar(255),
            [sku] nvarchar(32),
            [quantity_shipped] int,
            [item_price] money,
            [item_tax] money,
            [shipping_price] money,
            [shipping_tax] money,
            [item_promotion_discount] money,
            [ship_promotion_discount] money
        )

    insert into @t
        (
            [amazon_order_id_p1],
            [amazon_order_id_p2],
            [amazon_order_id_p3],
            [merchant_order_id],
            [shipment_id],
            [line],
            [purchase_date],
            [payments_date],
            [shipment_date],
            [reporting_date],
            [currency],
            [ship_service_level],
            [ship_city],
            [ship_state],
            [ship_postal_code],
            [ship_country],
            [carrier],
            [estimated_arrival_date],
            [fulfillment_center_id],
            [fulfillment_channel],
            [sales_channel],
            [sku],
            [quantity_shipped],
            [item_price],
            [item_tax],
            [shipping_price],
            [shipping_tax],
            [item_promotion_discount],
            [ship_promotion_discount]
        )
    select
        d.[amazon_order_id_p1],
        d.[amazon_order_id_p2],
        d.[amazon_order_id_p3],
        d.[merchant_order_id],
        d.[shipment_id],
        sum(1) over (partition by d.[amazon_order_id_p1],d.[amazon_order_id_p2],d.[amazon_order_id_p3]),
        d.[purchase_date],
        d.[payments_date],
        d.[shipment_date],
        d.[reporting_date],
        d.[currency],
        d.[ship_service_level],
        d.[ship_city],
        d.[ship_state],
        d.[ship_postal_code],
        d.[ship_country],
        d.[carrier],
        d.[estimated_arrival_date],
        d.[fulfillment_center_id],
        d.[fulfillment_channel],
        d.[sales_channel],
        d.[sku],
        d.[quantity_shipped],
        d.[item_price],
        d.[item_tax],
        d.[shipping_price],
        d.[shipping_tax],
        d.[item_promotion_discount],
        d.[ship_promotion_discount]
    from
        (
            select
                --header
                try_convert(int,parsename(replace([1],'-','.'),3)) [amazon_order_id_p1],
                try_convert(int,parsename(replace([1],'-','.'),2)) [amazon_order_id_p2],
                try_convert(int,parsename(replace([1],'-','.'),1)) [amazon_order_id_p3],
                left([3],32) [merchant_order_id],
                left([4],32) [shipment_id],
                try_convert(datetime2(0),[7]) [purchase_date], 
                try_convert(datetime2(0),[8]) [payments_date], 
                try_convert(datetime2(0),[9]) [shipment_date], 
                try_convert(datetime2(0),[10]) [reporting_date], 
                left([17],32) [currency],
                left([24],32) [ship_service_level],
                left([29],32) [ship_city],
                left([30],32) [ship_state],
                left([31],32) [ship_postal_code],
                left([32],32) [ship_country],
                left([43],32) [carrier],
                try_convert(date,[45]) [estimated_arrival_date],
                left([46],32) [fulfillment_center_id],
                left([47],32) [fulfillment_channel],
                left(lower([48]),db_sys.fn_minus_min0(len([48])-1)) [sales_channel],
                --line
                left([14],32) [sku],
                try_convert(int,[16]) [quantity_shipped],
                try_convert(money,[18]) [item_price],
                try_convert(money,[19]) [item_tax],
                try_convert(money,[20]) [shipping_price],
                try_convert(money,[21]) [shipping_tax],
                try_convert(money,[41]) [item_promotion_discount],
                try_convert(money,[42]) [ship_promotion_discount]
            from
                (
                    select
                        r.ordinal r,
                        c.value,
                        c.ordinal
                    from
                        string_split(@file_body,char(10), 1) r
                    cross apply
                        string_split(r.value,char(9), 1) c
                    where
                        r.ordinal > 1
                ) u
            pivot
                (
                    min(u.value)
                for
                    u.ordinal in 
                        (
                            [1],
                            [3],
                            [4],
                            [7],
                            [8],
                            [9],
                            [10],
                            [14],
                            [16],
                            [17],
                            [18],
                            [19],
                            [20],
                            [21],
                            [24],
                            [29],
                            [30],
                            [31],
                            [32],
                            [41],
                            [42],
                            [43],
                            [45],
                            [46],
                            [47],
                            [48]
                        )
                ) p
            ) d
        left join
            ext.amazon_import_sales_header h
        on
            (
                d.[amazon_order_id_p1] = h.[amazon_order_id_p1]
            and d.[amazon_order_id_p2] = h.[amazon_order_id_p2]
            and d.[amazon_order_id_p3] = h.[amazon_order_id_p3]
            )
    where
        (
            h.id is null
        or  @is_test = 1
        )

    if @is_test = 0

        begin

            insert into ext.amazon_import_sales_header
                (
                    [filelist_id],
                    [amazon_order_id_p1],
                    [amazon_order_id_p2],
                    [amazon_order_id_p3],
                    [merchant_order_id],
                    [shipment_id],
                    [purchase_date],
                    [payments_date],
                    [shipment_date],
                    [reporting_date],
                    [currency],
                    [ship_service_level],
                    [ship_city],
                    [ship_state],
                    [ship_postal_code],
                    [ship_country],
                    [carrier],
                    [estimated_arrival_date],
                    [fulfillment_center_id],
                    [fulfillment_channel],
                    [sales_channel]
                )
            select
                @filelist_id,
                t.[amazon_order_id_p1],
                t.[amazon_order_id_p2],
                t.[amazon_order_id_p3],
                u.[merchant_order_id],
                u.[shipment_id],
                u.[purchase_date],
                u.[payments_date],
                u.[shipment_date],
                u.[reporting_date],
                u.[currency],
                u.[ship_service_level],
                u.[ship_city],
                u.[ship_state],
                u.[ship_postal_code],
                u.[ship_country],
                u.[carrier],
                u.[estimated_arrival_date],
                u.[fulfillment_center_id],
                u.[fulfillment_channel],
                u.[sales_channel]
            from
                (
                    select distinct
                        [amazon_order_id_p1],
                        [amazon_order_id_p2],
                        [amazon_order_id_p3]
                    from
                        @t
                ) t
            cross apply
                (
                    select top 1
                        v.[merchant_order_id],
                        v.[shipment_id],
                        v.[purchase_date],
                        v.[payments_date],
                        v.[shipment_date],
                        v.[reporting_date],
                        v.[currency],
                        v.[ship_service_level],
                        v.[ship_city],
                        v.[ship_state],
                        v.[ship_postal_code],
                        v.[ship_country],
                        v.[carrier],
                        v.[estimated_arrival_date],
                        v.[fulfillment_center_id],
                        v.[fulfillment_channel],
                        v.[sales_channel]
                    from
                        @t v
                    where
                        (
                            t.[amazon_order_id_p1] = v.[amazon_order_id_p1]
                        and t.[amazon_order_id_p2] = v.[amazon_order_id_p2]
                        and t.[amazon_order_id_p3] = v.[amazon_order_id_p3]
                        )
                ) u

            insert into ext.amazon_import_sales_line
                (
                    [sales_header_id],
                    [sku],
                    [quantity_shipped],
                    [item_price],
                    [item_tax],
                    [shipping_price],
                    [shipping_tax],
                    [item_promotion_discount],
                    [ship_promotion_discount]
                )
            select
                id.[sales_header_id],
                t.[sku],
                t.[quantity_shipped],
                t.[item_price],
                t.[item_tax],
                t.[shipping_price],
                t.[shipping_tax],
                t.[item_promotion_discount],
                t.[ship_promotion_discount]
            from
                (
                    select
                        [amazon_order_id_p1],
                        [amazon_order_id_p2],
                        [amazon_order_id_p3],
                        [sku],
                        sum([quantity_shipped]) [quantity_shipped],
                        sum([item_price]) [item_price],
                        sum([item_tax]) [item_tax],
                        sum([shipping_price]) [shipping_price],
                        sum([shipping_tax]) shipping_tax,
                        sum([item_promotion_discount]) item_promotion_discount,
                        sum([ship_promotion_discount]) ship_promotion_discount
                    from
                        @t
                    group by
                        [amazon_order_id_p1],
                        [amazon_order_id_p2],
                        [amazon_order_id_p3],
                        [sku]
                ) t
            cross apply
                (
                    select top 1 
                        [id] [sales_header_id]
                    from 
                        ext.amazon_import_sales_header h 
                    where 
                        (
                            h.[amazon_order_id_p1] = t.[amazon_order_id_p1]
                        and h.[amazon_order_id_p2] = t.[amazon_order_id_p2]
                        and h.[amazon_order_id_p3] = t.[amazon_order_id_p3]
                        )
                ) id

            update ext.amazon_import_filelist set importTS = getutcdate() where id = @filelist_id

        end

    else

        begin

            select * from @t

        end

    set @eventDetail = 'Procedure Outcome: Success'

end try

begin catch

    set @error_count += 1

    if @error_count > 1 set @report_error = 0

    if @is_test = 0 insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage, report_error) values ('ext.sp_amazon_import_filelist', @auditLog_ID, error_line(), error_message(), @report_error)

    if @is_test = 0 update db_sys.procedure_schedule set error_count += 1 where procedureName = 'ext.sp_amazon_import_sales'

    set @eventDetail = 'Procedure Outcome: Failed'

end catch

if @is_test = 0 exec db_sys.sp_auditLog_end @eventDetail=@eventDetail,@placeHolder_ui=@place_holder

/* columns not imported:
    -- [2] [merchant-order-id],
    -- [3] [shipment-id],
    -- [4] [shipment-item-id],
    -- [5] [amazon-order-item-id],
    -- [6] [merchant-order-item-id],
    -- [11] [buyer-email],
    -- [12] [buyer-name],
    -- [13] [buyer-phone-number],
    -- [15] [product-name],
    -- [22] [gift-wrap-price],
    -- [23] [gift-wrap-tax],
    -- [25] [recipient-name],
    -- [26] [ship-address-1],
    -- [27] [ship-address-2],
    -- [28] [ship-address-3],
    -- [33] [ship-phone-number],
    -- [34] [bill-address-1],
    -- [35] [bill-address-2],
    -- [36] [bill-address-3],
    -- [37] [bill-city],
    -- [38] [bill-state],
    -- [39] [bill-postal-code],
    -- [40] [bill-country],
    --[44] [tracking_number],
*/