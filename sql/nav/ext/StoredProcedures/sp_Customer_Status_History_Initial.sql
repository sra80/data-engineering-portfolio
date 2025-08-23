create or alter procedure ext.sp_Customer_Status_History_Initial

as

set nocount on

declare @cus nvarchar(36)

declare [d611a30a-771b-48b4-8a2a-c6b2cf772066] cursor for Select No_ from (select [Sell-to Customer No_] No_ from [dbo].[UK$Sales Header Archive] where [Archive Reason] = 3 union select [Sell-to Customer No_] from dbo.Sales_Header union select cus from ext.Customer_Order_History) x where x.No_ not in (select No_ from ext.Customer_Status_History)

open [d611a30a-771b-48b4-8a2a-c6b2cf772066]

fetch next from [d611a30a-771b-48b4-8a2a-c6b2cf772066] into @cus

while @@fetch_status = 0

begin

insert into ext.Customer_Status_History (No_, [Start Date], [Status], [Last Order])
select @cus, event_date, customer_status, last_order from ext.fn_Customer_Status_History(@cus)

fetch next from [d611a30a-771b-48b4-8a2a-c6b2cf772066] into @cus

end

close [d611a30a-771b-48b4-8a2a-c6b2cf772066]
deallocate [d611a30a-771b-48b4-8a2a-c6b2cf772066]
GO
