create or alter function stock.fn_qa_status
    (
        @batch_id int
    )

returns table

as

return

select
    isnull(qs.is_qa,convert(bit,0)) is_qa,
    isnull(qs.is_stop,convert(bit,0)) is_stop,
    qs.expected_release
from
    (
        select
            @batch_id batch_id
    ) v
left join
    (
        select
            ibi.ID batch_id,
            is_qa = case when lni.[Test Quality] = 4 and lni.[Blocked] = 1 then 1 else 0 end,
            is_stop = case when lni.[Test Quality] = 2 and lni.[Blocked] = 1 then 1 else 0 end,
            expected_release = 
                case when lni.[Test Quality] = 4 and lni.[Blocked] = 1 
                    then dateadd
                        (week,
                            case when i.[Range Code] = N'ELITE' 
                                then 
                                    3 
                                else 
                                    0 
                                end,
                            dateadd
                                (day,5,db_sys.foweek((select min(x.x) from (values (purchase.[Expected Receipt Date]),(getutcdate())) as x(x)),0))
                        )
            end
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
        join
            hs_consolidated.Item i
        on
            (
                ibi.company_id = i.company_id
            and ibi.sku = i.No_
            )
        outer apply
            (
                select top 1
                    pl.[Expected Receipt Date]
                from
                    hs_consolidated.[Item Ledger Entry] ile
                join
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
                    (
                        ibi.company_id = ile.company_id
                    and ibi.sku = ile.[Item No_]
                    and ibi.variant_code = ile.[Variant Code]
                    and ibi.batch_no = ile.[Lot No_]
                    )
            ) purchase
    ) qs
on
    (
        v.batch_id = qs.batch_id
    )