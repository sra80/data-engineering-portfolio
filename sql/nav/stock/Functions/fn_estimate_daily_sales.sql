create or alter function [stock].[fn_estimate_daily_sales]
    (
        @item_id int,
        @location_id int
    )

returns decimal(12,6)

as

begin

declare @estimate_daily_sales decimal(12,6)

select top 1
    -- @estimate_daily_sales = isnull(max(il.avg_sales),ext.fn_Item_Location_avg_sales(@item_id,@location_id))
    @estimate_daily_sales = il.sales_single
from
    ext.Item_Location il
where
    (
        il.item_id = @item_id
    and il.location_id = @location_id
    )

return @estimate_daily_sales

end
GO
