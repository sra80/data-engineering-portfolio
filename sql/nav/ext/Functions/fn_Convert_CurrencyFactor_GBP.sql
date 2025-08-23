--ext.fn_Convert_CurrencyFactor_GBP (*new function*) *done*

create   function ext.fn_Convert_CurrencyFactor_GBP
    (
        @CurrencyFactor float,
        @company_id int,
        @transaction_date date
    )

returns float

as

begin

select top 1
    @CurrencyFactor = @CurrencyFactor*[Exchange Rate Amount]
from
    [dbo].[UK$Currency Exchange Rate]
where
    (
        [Currency Code] = (select top 1 [LCY Code] from hs_consolidated.[General Ledger Setup] where company_id = @company_id)
    and [Starting Date] <= @transaction_date 
    )
order by
    [Starting Date] desc

return @CurrencyFactor

end
GO
