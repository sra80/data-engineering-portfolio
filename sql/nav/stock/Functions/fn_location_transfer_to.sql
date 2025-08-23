CREATE   function [stock].[fn_location_transfer_to]
    (
        @company_id int,
        @location_code nvarchar(20),
        @transfer_order_ref nvarchar(20)
    )

returns nvarchar(20)

as

begin

if (select top 1 [Use As In-Transit] from hs_consolidated.Location where company_id = @company_id and Code = @location_code) = 1

    begin

        select top 1 @location_code = th.[Transfer-to Code] from hs_consolidated.[Transfer Header] th where th.company_id = @company_id and th.No_ = @transfer_order_ref

    end

return @location_code

end
GO
