--ext.fn_Convert_Currency_GBP (*new function*) *done*

create   function ext.fn_Convert_Currency_GBP
    (
        @value float,
        @company_id int,
        @transaction_date date
    )

returns float

as

begin

if 
    
    @company_id = 1 return @value

else

select top 1
    @value = db_sys.fn_divide(@value,[Exchange Rate Amount],@value)
from
    [dbo].[UK$Currency Exchange Rate]
where
    (
        [Currency Code] = (select top 1 [LCY Code] from hs_consolidated.[General Ledger Setup] where company_id = @company_id)
    and [Starting Date] <= @transaction_date 
    )
order by
    [Starting Date] desc

return @value

end
GO
