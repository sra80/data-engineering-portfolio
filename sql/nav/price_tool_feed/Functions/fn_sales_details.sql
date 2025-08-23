create or alter function [price_tool_feed].[fn_sales_details]
    (
        @channel_code nvarchar(10),
        @order_no nvarchar(20),
        @integration_code nvarchar(32),
        @customer_no nvarchar(20),
        @date date,
        @item_no nvarchar(20),
        @customer_id int = null
    )

returns @t table (store_id int, shelf_price money, fullprice money, is_new_sub bit, cost_price money)

as

begin


declare @price_list nvarchar(20), @store_id int, @standard_ss money, @shelf_price money, @fullprice money, @cost_price money, @is_sub bit, @is_online bit, @is_new_sub bit = 0, @sub_no nvarchar(20)

if @customer_id is null select @customer_id = hs_identity.fn_Customer(1,@customer_no)

select @store_id = store_id from price_tool_feed.stores where customer_id = @customer_id

if @store_id >= 0 

    begin

        select 
            @price_list = isnull(nullif([Customer Price Group],''),'DEFAULT') 
        from 
            [dbo].[UK$Customer] 
        where 
            (
                No_ = @customer_no
            )
    end

else

    begin
        
        select
            @store_id = store_id,
            @is_sub = is_sub,
            @is_online = is_online,
            @price_list = 'DEFAULT'
        from
            price_tool_feed.stores
        where
            (
                platform_id = ext.fn_Platform(1,@channel_code,@order_no,@integration_code,default)
            and is_ss1 = 0
            )
        
        select 
            @is_new_sub = 1 
        from 
            [dbo].[UK$Subscriptions Header] s 
        where 
            (
                [Original Order No_] = @order_no
            )

        if @is_new_sub = 1

            begin

            select top 1
                @store_id = store_id
            from
                price_tool_feed.stores
            where
                (
                    is_sub = 1
                and is_online = @is_online
                and is_ss1 = 0
                )


            end

        else if @is_sub = 1

            begin

                select @sub_no = [Subscription No_] from ext.[Sales_Header] where company_id = 1 and [Sales Order Status] = 1 and [No_] = @order_no

                if @sub_no is null 
                
                    select @sub_no = [Subscription No_] from ext.[Sales_Header_Archive] where company_id = 1 and [No_] = @order_no

                if @sub_no is null 
                
                    select @sub_no = [Subscription No_] from [dbo].[UK$Sales Header Archive] where [Archive Reason] = 3 and [No_] = @order_no

                if len(@sub_no) > 0

                    begin

                    select @order_no = [Original Order No_] from [dbo].[UK$Subscriptions Header] s where [No_] = @sub_no

                    set @channel_code = null

                    set @integration_code = null

                    select @channel_code = [Channel Code], @integration_code = [Inbound Integration Code] from ext.Sales_Header where company_id = 1 and [No_] = @order_no and [Sales Order Status] = 1

                    if @channel_code+@integration_code is null 
                    
                        select @channel_code = [Channel Code], @integration_code = [Inbound Integration Code] from ext.Sales_Header_Archive where company_id = 1 and [No_] = @order_no

                    if @channel_code+@integration_code is null 
                    
                        select @channel_code = [Channel Code], @integration_code = [Inbound Integration Code] from [dbo].[UK$Sales Header Archive] where [Archive Reason] = 3 and [No_] = @order_no

                            select
                                @is_online = is_online
                            from
                                price_tool_feed.stores
                            where
                                (
                                    platform_id = ext.fn_Platform(1,@channel_code,@order_no,@integration_code,default)
                                )
                
                    end

            end

    end

select
    @shelf_price = min([Unit Price])
from
    [dbo].[UK$Sales Price]
where
    (
        [Item No_] = @item_no
    and [Sales Type] = 1
    and [Sales Code] = @price_list
    and [Starting Date] <= @date
    and [Ending Date] >= @date
    )

if @is_sub = 1 or @is_new_sub = 1

    begin

        select
            @standard_ss = convert(money,min(sp.[Unit Price] - isnull(ss_discount.discount,0)))
        from
            [dbo].[UK$Sales Price] sp
        join
            ext.Item i
        on
            (
                i.company_id = 1
            and sp.[Item No_] = i.No_
            )
        outer apply
            (
                select 
                    max(discount.discount) discount
                from
                    price_tool_feed.subs_fixed_discount discount
                where
                    (
                        discount.price_group_id = (select ID from ext.Customer_Price_Group where company_id = 1 and code = 'SUBDEFAULT')
                    and sp.[Unit Price] >= discount.price
                    )
            ) ss_discount
        where
            (
                sp.[Item No_] = @item_no
            and sp.[Sales Type] = 1
            and sp.[Sales Code] = 'FULLPRICES'
            and sp.[Starting Date] <= @date
            and sp.[Ending Date] >= @date
            and nullif(sp.[Currency Code],'') is null
            )

    select
        @shelf_price = min(price)
    from
        (
            values
                (@shelf_price),
                (@standard_ss)
        )
            as
                x(price)
            
    end

select
    @fullprice = min([Unit Price])
from
    [dbo].[UK$Sales Price]
where
    (
        [Item No_] = @item_no
    and [Sales Type] = 1
    and [Sales Code] = 'FULLPRICES'
    and [Starting Date] <= @date
    and [Ending Date] >= @date
    )

select top 1
    @cost_price = cost_actual
from
   ext.Item_UnitCost
where
    (
        reviewedTSUTC <= eomonth(@date)
    and item_ID = (select ID from ext.Item where company_id = 1 and No_ = @item_no)
    and cost_actual > 0
    )
order by 
    row_version desc

insert into @t (store_id, shelf_price, fullprice, is_new_sub, cost_price) values (isnull(@store_id,-1), isnull(@shelf_price,0), isnull(@fullprice,0), isnull(@is_new_sub,0), isnull(@cost_price,0))

return

end
GO
