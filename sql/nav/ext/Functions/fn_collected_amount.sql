CREATE function [ext].[fn_collected_amount]
	(
		@buying_reference_no nvarchar(32)
	)

returns money

as

begin

declare @collected_amount money

	
select 
	@collected_amount = sum(pr.[Collected Amount])
from
	[dbo].[Payment_Refund] pr
where
	pr.[Buying Reference No_] = @buying_reference_no


return @collected_amount

end
GO
