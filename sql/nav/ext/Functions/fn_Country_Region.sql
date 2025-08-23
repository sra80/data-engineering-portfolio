--ext.fn_Country_Region (function) *done*

create   function ext.fn_Country_Region
    (
        @company_id int,
        @country_code nvarchar(10)
    )

returns int

as

begin

declare @ID int

select 
    @ID = ID
from 
    ext.Country_Region
where
    (
        company_id = @company_id
    and country_code = @country_code
    )

return @ID

end
GO
