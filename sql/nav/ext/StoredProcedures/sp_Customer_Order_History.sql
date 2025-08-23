create or alter procedure ext.sp_Customer_Order_History

as

set nocount on

declare @rc int = 1

while @rc > 0

begin

    insert into ext.Customer_Order_History (order_ref, order_date, cus, integration_code, channel_code)
    select top 1000
        No_,
        [Order Date],
        [Sell-to Customer No_],
        [Inbound Integration Code],
        [Channel Code]
    from
        ext.Sales_Header_Archive
    where
        (
            company_id = 1
        and No_ not in (select order_ref from ext.Customer_Order_History)
        )

    set @rc = @@rowcount

end