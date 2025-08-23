
create function [ext].[fn_Platform_Grouping]
    (
        @company_id int = null,
        @Channel_Code nvarchar(32),
        @Order_Number nvarchar(32),
        @Integration_Code nvarchar(32),
        @is_null int = 0 -- return no match as
    )

returns int

as

begin

declare @group int

select
    @group = p.Group_ID
from
    ext.Platform_Setup ps
join
    ext.Platform p
on
    (
        ps.PlatformID = p.ID
    )
where
    (
        ps.company_id = @company_id
    and ps.Channel_Code = isnull(nullif(@Channel_Code,''),'PHONE')
    and ps.Order_Prefix = left(@Order_Number,abs(patindex('%[^A-Z]%',@Order_Number)-1))
    and ps.Integration_Code = isnull(nullif(@Integration_Code,''),'NAV')
    )

return coalesce(@group,(select p.Group_ID from ext.Platform_Exceptions pe join ext.Platform p on (pe.PlatformID = p.ID) where company_id = @company_id and order_no = @Order_Number),@is_null)

end
GO
