create or alter function [stock].[fn_qa_status_qa_release]
    (
        @batch_id int
    )

returns date

as

begin

declare @expected_release date, @is_qa bit = 0

select top 1
    @expected_release = 
        case when lni.[Test Quality] = 4 or lni.[Blocked] = 1 
            then dateadd
                (week,
                    case when i.[Range Code] = N'ELITE' 
                        then 
                            3 
                        else 
                            0 
                        end,
                    dateadd
                        (day,5,db_sys.foweek(pl.[Expected Receipt Date],0))
                )
    end,
    @is_qa = 
        case when lni.[Test Quality] = 4 or lni.[Blocked] = 1 
    then
        1
    end
from
    ext.Item_Batch_Info ibi
join
    hs_consolidated.Item i
on
    (
        ibi.company_id = i.company_id
    and ibi.sku = i.No_
    )
join
    hs_consolidated.[Lot No_ Information] lni
on
    (
        ibi.company_id = lni.company_id
    and ibi.sku = lni.[Item No_]
    and ibi.variant_code = lni.[Variant Code]
    and ibi.batch_no = lni.[Lot No_]
    )
join
    hs_consolidated.[Item Ledger Entry] ile
on
    (
        ibi.company_id = ile.company_id
    and ibi.sku = ile.[Item No_]
    and ibi.variant_code = ile.[Variant Code]
    and ibi.batch_no = ile.[Lot No_]
    )
left join
    hs_consolidated.[Purchase Line] pl
on
    (
        ile.company_id = pl.company_id
    and ile.[Entry Type] = 6
    and ile.[Location Code] = pl.[Location Code]
    and ile.[Item No_] = pl.[No_]
    and ile.[Document No_] = isnull(nullif(pl.[Prod_ Order No_],''),pl.[Document No_])
    )
where
    ibi.ID = @batch_id

if @is_qa = 1 and (@expected_release is null or @expected_release < dateadd(day,5,db_sys.foweek(getutcdate(),0)))

    begin

    set @expected_release = dateadd(day,5,db_sys.foweek(getutcdate(),0))

    end

return @expected_release

end