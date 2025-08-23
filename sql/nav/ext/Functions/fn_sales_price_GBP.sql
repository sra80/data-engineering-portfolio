create   function [ext].[fn_sales_price_GBP]
	(
        @company_id int,
        @item_sku nvarchar(20),
		@date date,
		@sales_code nvarchar(20)
	)

returns money

as

begin

declare @price money

select top 1
	@price = 
        isnull
            (
                ext.fn_Convert_Currency_GBP([Unit Price],@company_id,@date)
            ,
                ext.fn_sales_price(@item_sku,@date,@sales_code)
            )
from
	hs_consolidated.[Sales Price] sp
where
    (
        sp.company_id = @company_id
    and sp.[Sales Code] = @sales_code
    and sp.[Item No_] = @item_sku
    and sp.[Starting Date] <= @date
    and sp.[Ending Date] >= @date
    )

return @price

end
GO
