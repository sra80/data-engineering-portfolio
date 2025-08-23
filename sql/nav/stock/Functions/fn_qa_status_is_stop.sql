create or alter function [stock].[fn_qa_status_is_stop]
    (
        @batch_id int
    )

returns bit

as

begin

declare @is_stop bit = 0

select
    @is_stop = case when lni.[Test Quality] = 2 and lni.[Blocked] = 1 then 1 else 0 end
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
where
    (
        ibi.ID = @batch_id
    )

return @is_stop

end
GO
