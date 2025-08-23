create or alter function [stock].[fn_qa_status_is_qa]
    (
        @batch_id int
    )

returns bit

as

begin

declare @is_qa bit = 0

select
    @is_qa = case when lni.[Test Quality] = 4 and lni.[Blocked] = 1 then 1 else 0 end
from
    ext.Item_Batch_Info ibi
join
    hs_consolidated.[Lot No_ Information] lni
on
    (
        ibi.company_id = lni.company_id
    and ibi.sku = lni.[Item No_]
    and ibi.variant_code = lni.[Variant Code]
    and ibi.batch_no = lni.[Lot No_]
    )
-- join
--     hs_consolidated.[Item] i
-- on
--     (
--         lni.company_id = i.company_id
--     and lni.[Item No_] = i.[No_]
--     )
where
    (
        ibi.ID = @batch_id
    )

return @is_qa

end
GO
