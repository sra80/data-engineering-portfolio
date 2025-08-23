CREATE function ext.fn_sales_price
	(
		 @item_sku nvarchar(32)
		,@date date
		,@sales_code nvarchar(32)
	)

returns money

as

begin

declare @price money

select top 1
	@price = [Unit Price]
from
	[UK$Sales Price] sp
where
	sp.[Sales Code] = @sales_code
and sp.[Item No_] = @item_sku
and sp.[Starting Date] <= @date
and sp.[Ending Date] >= @date


return @price

end
GO
