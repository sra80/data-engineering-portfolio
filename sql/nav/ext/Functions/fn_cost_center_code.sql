CREATE function [ext].[fn_cost_center_code]
    (
        @dimension_set_id int,
        @country_code nvarchar(2)
    )

returns nvarchar(40)

as

begin

declare @cost_center_code nvarchar(40)

if @country_code not in (select Code from [dbo].[UK$Country_Region] where [Delivery Zone] = 'UK') set @cost_center_code = 'INT'

else

select @cost_center_code = [Dimension Value Code] from [dbo].[UK$Dimension Set Entry] where [Dimension Code] = 'SALE.CHANNEL' and [Dimension Set ID] = @dimension_set_id

return isnull(@cost_center_code,'D2C')

end
GO
