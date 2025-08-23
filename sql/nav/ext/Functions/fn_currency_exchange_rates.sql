create or alter function [ext].[fn_currency_exchange_rates]

(
	@date date,
	@currency nvarchar(3)
)

returns decimal (38,20)

as

begin

declare @era decimal(38,20)

if @currency = 'GBP' set @era = 1

else

select top 1
	-- [Currency Code]
	--,convert(date,[Starting Date]) [Starting Date]
	--,convert(date,isnull(nullif(lead([Starting Date],1,0) over (partition by [Currency Code] order by [Currency Code],[Starting Date]),'19000101'),getdate())) [Ending Date]
	@era = [Exchange Rate Amount]
from
	[dbo].[UK$Currency Exchange Rate] cer
where
	[Currency Code] = @currency
and [Starting Date] <= @date
order by
	[Starting Date] desc

return @era

end
GO
