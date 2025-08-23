CREATE view [stock].[Product_Channel]

as

select
    i.item_id,
    i.company_id,
    c.[Channel Group],
    c.[Channel Code],
    convert(bit,case when ic.company_id is null then 0 else 1 end) is_enabled,
    ec.is_visible_oos_plr
from
    (
        select
            company_id,
            No_,
            ID item_id
        from
            ext.Item
    ) i
cross apply
    (
        select distinct
            ic.company_id,
            ic.[Channel Code],
            c.Channel_Code,
            cg.[Description] [Channel Group]
        from
            hs_consolidated.[Item Channel] ic
        join
            ext.Channel c
        on
            (
                ic.company_id = c.company_id
            and ic.[Channel Code] = c.Channel_Code
            )
        join
            ext.Channel_Grouping cg
        on
            (
                c.Group_Code = cg.Code
            )
        where
            (
                len(ic.[Channel Code]) > 0
            )
    ) c
join
    ext.Channel ec
on
    (
        c.company_id = ec.company_id
    and c.[Channel Code] = ec.Channel_Code
    )
left join
    hs_consolidated.[Item Channel] ic
on
    (
        i.company_id = c.company_id
    and i.company_id = ic.company_id
    and i.No_ = ic.[Item No_]
    and c.[Channel Code] = ic.[Channel Code]
    )
where
    (
        i.company_id = c.company_id
    )
GO
