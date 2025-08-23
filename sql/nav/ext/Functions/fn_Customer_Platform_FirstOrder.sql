create or alter function [ext].[fn_Customer_Platform_FirstOrder]
    (
        @cus nvarchar(20)
    )

returns table

as

return
(
with sales as
    (
    select 
        order_date,
        'SCV' integration_code,
        'XX' order_prefix,
        method channel_code
    from
        scv.sales
    where
        cus = @cus

    union all

    select
        h.[Order Date],
        isnull(nullif(h.[Inbound Integration Code],''),'NAV'),
        left(h.No_,abs(patindex('%[^A-Z]%',h.No_)-1)),
        h.[Channel Code]
    from
        dbo.Sales_Header h
    where
        (
            h.[Sales Order Status] = 1
        and h.[Sell-to Customer No_] = @cus
        )

    union all

    select
        h.[Order Date],
        isnull(nullif(h.[Inbound Integration Code],''),'NAV'),
        left(h.No_,abs(patindex('%[^A-Z]%',h.No_)-1)),
        h.[Channel Code]
    from
        dbo.Sales_Header_Archive h
    where
        (
            h.[Archive Reason] = 3
        and h.[Sell-to Customer No_] = @cus
        )

    union all

    select
        h.order_date,
        isnull(nullif(h.integration_code,''),'NAV'),
        left(h.order_ref,abs(patindex('%[^A-Z]%',h.order_ref)-1)),
        h.channel_code
    from
        ext.Customer_Order_History h
    where
        cus = @cus
    )

select top 1
    convert(date,sales.order_date) order_date,
    sales.channel_code,
    isnull(ps.platformID,999) platformID
from
    sales
left join
    ext.Platform_Setup ps
on
    (
        sales.channel_code = ps.channel_code 
    and sales.order_prefix = ps.order_prefix 
    and sales.integration_code = ps.integration_code
    )
order by
    sales.order_date
)
GO
