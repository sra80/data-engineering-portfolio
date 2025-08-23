create or alter view ext.vw_sales_price_missing_eot

as

select
    c.Company,
    sp.[Item No_] [Item Code],
    sp.[Sales Code],
    sp.[Ending Date] [Price End Date],
    i.lastOrder [Last Order Date],
    up.[Unit Price]
from
    (
        select
            sp.company_id,
            sp.[Currency Code],
            sp.[Sales Code],
            sp.[Unit of Measure Code],
            sp.[Item No_],
            sp.[Variant Code],
            convert(date,max(sp.[Ending Date])) [Ending Date]
        from
            hs_consolidated.[Sales Price] sp
        join
            ext.Customer_Price_Group cpg
        on
            (
                sp.company_id = cpg.company_id
            and sp.[Sales Code] = cpg.code
            )
        join
            hs_consolidated.Item i
        on
            (
                sp.company_id = i.company_id
            and sp.[Item No_] = i.No_
            and cpg.is_ss = i.[Subscribe and Save]
            )
        where
            (
                sp.[Sales Type] = 1
            and cpg.check_missing = 1
            and i.[Status] in (0,1)
            )
        group by
            sp.company_id,
            sp.[Currency Code],
            sp.[Sales Code],
            sp.[Unit of Measure Code],
            sp.[Item No_],
            sp.[Variant Code]
        having
            max(sp.[Ending Date]) < datefromparts(2099,12,31)
    ) sp
join
    ext.Item i
on
    (
        sp.company_id = i.company_id
    and sp.[Item No_] = i.No_
    )
join
    db_sys.Company c
on
    (
        sp.company_id = c.ID
    )
cross apply
    (
        select top 1
            ic.[Channel Code]
        from
            hs_consolidated.[Item Channel] ic
        join
            ext.Channel ec
        on
            (
                ic.company_id = ec.company_id
            and ic.[Channel Code] = ec.Channel_Code
            )
        where
            (
                i.company_id = ic.company_id
            and i.No_ = ic.[Item No_]
            and ec.is_price_checked = 1
            )
    ) ch
cross apply
    (
        select top 1
            convert(money,round(f.[Unit Price],2)) [Unit Price]
        from
            hs_consolidated.[Sales Price] f
        where
            (
                sp.company_id = f.company_id
            and sp.[Currency Code] = f.[Currency Code]
            and sp.[Sales Code] = f.[Sales Code]
            and sp.[Unit of Measure Code] = f.[Unit of Measure Code]
            and sp.[Item No_] = f.[Item No_]
            and sp.[Variant Code] = f.[Variant Code]
            and sp.[Ending Date] = f.[Ending Date]
            )
        order by
            f.[Unit Price]
    ) up
where
    (
        i.lastOrder > sp.[Ending Date]
    )