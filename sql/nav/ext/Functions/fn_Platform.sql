
CREATE   function [ext].[fn_Platform]
    (
        @company_id int = null,
        @Channel_Code nvarchar(32),
        @Order_Number nvarchar(32),
        @Integration_Code nvarchar(32),
        @is_null int = 999 -- return no match as
    )

returns int

as

begin

declare @platform int

select
    @platform = ps.PlatformID
from
    ext.Platform_Setup ps
where
    (
        ps.company_id = @company_id
    and ps.Channel_Code = isnull(nullif(@Channel_Code,''),'PHONE')
    and ps.Order_Prefix = left(@Order_Number,abs(patindex('%[^A-Z]%',@Order_Number)-1))
    and ps.Integration_Code = isnull(nullif(@Integration_Code,''),'NAV')
    )

return coalesce(@platform,(select PlatformID from ext.Platform_Exceptions where company_id = @company_id and order_no = @Order_Number),@is_null)

end
GO
