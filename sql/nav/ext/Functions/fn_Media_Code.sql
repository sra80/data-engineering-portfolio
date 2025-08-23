--ext.fn_Media_Code (function) *done*

create   function ext.fn_Media_Code
    (
        @company_id int,
        @media_code nvarchar(10)
    )

returns int

as

begin

declare @media_id int

select
    @media_id = ID
from
    ext.Media_Code
where
    (
        company_id = @company_id
    and media_code = @media_code
    )

if @media_id is null if len(@media_code) > 0 set @media_id = -2 else set @media_id = -1

return @media_id

end
GO
