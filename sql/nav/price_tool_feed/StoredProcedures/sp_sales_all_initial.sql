create procedure price_tool_feed.sp_sales_all_initial

as

declare @y int, @m int, @date date, @message nvarchar(max)

    select
        @date = dateadd(month,1,max([date]))
    from
        price_tool_feed.sales_all

    if @date is null set @date = datefromparts(year(getdate())-2,1,1)

while @date <= dateadd(day,1,eomonth(getdate(),-1))

    begin

    select 
        @y = year(@date),
        @m = month(@date)

    insert into price_tool_feed.sales_all (id, store_id, article_id, [date], price_type, quantity, price, shelf_price, cost_price, customer_id)
    select 
        id, store_id, article_id, [date], price_type, quantity, price, shelf_price, cost_price, customer_id
    from
        price_tool_feed.fn_sales_month(@y,@m) s

    set @message = concat('Yieldigo sale data load for ',format(@date,'MMMM yyyy'),' has completed.')

    exec db_sys.sp_email_notifications
        @to = 'user@example.com',
        @subject = 'Yieldigo Sales Data Load Upload',
        @bodyIntro = @message,
        @greeting = 0

    select @date = dateadd(month,1,@date)

end
GO
