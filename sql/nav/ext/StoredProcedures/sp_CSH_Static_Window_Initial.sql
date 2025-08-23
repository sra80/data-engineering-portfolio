CREATE procedure ext.sp_CSH_Static_Window_Initial

as

set nocount on

declare @cus nvarchar(36)

declare [6b6bce39-144c-4350-a167-bb427e9362df] cursor for select No_ from (select [Sell-to Customer No_] No_ from dbo.Sales_Header_Archive where [Archive Reason] = 3 union select [Sell-to Customer No_] from dbo.Sales_Header) x where x.No_ not in (select No_ from ext.CSH_Static_Window)

open [6b6bce39-144c-4350-a167-bb427e9362df]

fetch next from [6b6bce39-144c-4350-a167-bb427e9362df] into @cus

while @@fetch_status = 0

begin

insert into ext.CSH_Static_Window (No_, [Start Date], [Status], [Last Order])
select @cus, event_date, customer_status, last_order from ext.fn_CSH_Static_Window(@cus)

fetch next from [6b6bce39-144c-4350-a167-bb427e9362df] into @cus

end

close [6b6bce39-144c-4350-a167-bb427e9362df]
deallocate [6b6bce39-144c-4350-a167-bb427e9362df]
GO
