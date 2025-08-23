--ext.fn_Payment_Method_ID (function) *done*

create or alter function ext.fn_Payment_MethodID
    (
        @company_id int,
        @pm_code nvarchar(10) = null,
        @buying_reference_no nvarchar(32) = null
    )

returns int

as

begin

declare @pm_id int

-- if @pm_code is null select @pm_code = ext.fn_payment_method(@company_id,@buying_reference_no)

select
    @pm_id = ID
from
    ext.Payment_Method
where
    (
        company_id = @company_id
    and pm_code = isnull(nullif(@pm_code,''),'unknown')
    )

return @pm_id

end
GO
