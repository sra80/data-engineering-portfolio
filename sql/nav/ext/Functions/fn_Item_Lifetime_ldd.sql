CREATE function [ext].[fn_Item_Lifetime_ldd]
    (
        @batch_id int
    )

returns date

as

begin

declare @ldd date

declare
    @company_id int,
    @sku nvarchar(20),
    @variant_code nvarchar(10),
    @batch_no nvarchar(20),
    @item_tracking_code nvarchar(10),
    @daily_dose decimal(38,20),
    @pack_size decimal(38,20)

select
    @company_id = company_id,
    @sku = sku,
    @variant_code = variant_code,
    @batch_no = batch_no,
    @ldd = ldd
from
    ext.Item_Batch_Info
where
    ID = @batch_id

select
    @item_tracking_code = [Item Tracking Code],
    @daily_dose = [Daily Dose],
    @pack_size = [Pack Size]
from
    hs_consolidated.Item
where
    (
        company_id = @company_id
    and No_ = @sku
    )

-- select top 1 @ldd = [Latest Despatch Date] from ext.fn_Item_Lifetime
--     (
--         @company_id,
--         @sku,
--         @variant_code,
--         @batch_no,
--         @item_tracking_code,
--         @daily_dose,
--         @pack_size
--     )
    
return @ldd

end
GO
