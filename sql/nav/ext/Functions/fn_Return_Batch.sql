ALTER FUNCTION [ext].[fn_Return_Batch]
(
    @company int,
    @orderNo nvarchar(20),
    @item nvarchar(20)
)

returns nvarchar(20)

as

begin

declare @lot nvarchar(20)

select top 1
    @lot = ile.[Lot No_]
from
    [hs_consolidated].[Return Receipt Header] rrh
join   
    [hs_consolidated].[Return Receipt Line] rrl
on
	(
		rrl.[Document No_] = rrh.[No_]
	and rrl.[company_id] = rrh.[company_id]
	)
join
    [hs_consolidated].[Sales Invoice Header] sih
on
    (
        rrh.[company_id] = sih.[company_id]
    and nullif(rrh.[Sales Order Reference],'') = sih.[Order No_]
    )
join
     [hs_consolidated].[Sales Invoice Line] sil
on
    (
        sih.[company_id] = sil.[company_id]
    and sih.[No_] = sil.[Document No_]
    and sil.[No_] = rrl.[No_]
    )
join
    [hs_consolidated].[Value Entry] ve
on
    (
        ve.[company_id] = sil.[company_id]
    and ve.[Document No_] = sil.[Document No_]
    and ve.[Item No_] = sil.[No_]
    )
join
    [hs_consolidated].[Item Ledger Entry] ile
on
    (
        ile.[company_id] = ve.[company_id]
    and ile.[Entry No_] = ve.[Item Ledger Entry No_]
    )
where
    rrh.[company_id] = @company
and rrh.[Sales Order Reference] = @orderNo
and rrl.[No_] = @item

return @lot

end
GO