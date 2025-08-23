create procedure ext.sp_first_order_range

as

declare @rowcount int = 1

while @rowcount > 0

begin

update x set
    x.first_order_range = y.first_order_range
from
    marketing.CSH_Moving_Extended_SKU x
join
    (
        select top 1000  cus, _start_date, channel_code, sku, order_date, isnull(ext.fn_first_order_range(cus,sku),datefromparts(1900,1,1)) first_order_range from marketing.CSH_Moving_Extended_SKU s join [dbo].[UK$Item] i on s.sku = i.No_ where s.first_order_range is null and i.[Type] = 0
    ) y
on
    (
        x.cus = y.cus 
    and x._start_date = y._start_date 
    and x.channel_code = y.channel_code 
    and x.sku = y.sku 
    and x.order_date = y.order_date
    )

set @rowcount = @@rowcount

end
GO
