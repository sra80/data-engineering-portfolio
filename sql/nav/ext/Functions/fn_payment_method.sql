create   function [ext].[fn_payment_method]
	(
		@company_id int,
        @buying_reference_no nvarchar(32)
	)

returns nvarchar(32)

as

begin

declare @payment_method nvarchar(64)

select top 1
	@payment_method = pr.[Payment Method Code]
from
	hs_consolidated.[Payment_Refund] pr
where
    (
        pr.company_id = @company_id
    and pr.[Buying Reference No_] = @buying_reference_no
    and len(pr.[Payment Method Code]) > 0
    )
order by
	[Collected Amount (LCY)] desc

if @payment_method is null set @payment_method = 'unknown'

return @payment_method

end
GO
