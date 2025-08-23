create view price_tool_feed.range_reassignment

as

with x as
    (
        select
            isnull(cat.parent_category_id,cat_none.parent_category_id) ibg,
            ii.[Range Code] rc,
            ii.No_ sku,
            dense_rank() over (partition by isnull(cat.parent_category_id,cat_none.parent_category_id) order by ii.[Range Code]) dr
        from
            ext.Item i
        join
            hs_consolidated.[Item] ii
        on
            (
                i.company_id = ii.company_id
            and i.No_ = ii.No_        
            )
        join
            (
                select
                    company_id,
                    [Item No_]
                from
                    hs_consolidated.[Item Channel] ic
                where
                    (
                        ic.[Channel Code] = 'WEB'
                    )
            ) ic
        on
            (
                ii.company_id = ic.company_id
            and ii.No_ = ic.[Item No_]
            )
        join
            db_sys.Company c
        on
            ii.company_id = c.ID
        join
            hs_consolidated.[Sales & Receivables Setup] srs
        on
            (
                c.ID = srs.company_id
            )
        left join
            hs_consolidated.[VAT Posting Setup] vps
        on
            (
                ii.company_id = vps.company_id
            and srs.[VAT Bus_ Posting Gr_ (Price)] = vps.[VAT Bus_ Posting Group]
            and ii.[VAT Prod_ Posting Group] = vps.[VAT Prod_ Posting Group]
            )
        outer apply
            (
                select top 1
                    (iav.company_id*10000)+iav.ID parent_category_id
                from
                    hs_consolidated.[Item Attribute] ia
                join
                    hs_consolidated.[Item Attribute Value] iav
                on
                    (
                        ia.company_id = iav.company_id
                    and ia.ID = iav.[Attribute ID]
                    )
                join
                    hs_consolidated.[Item Attribute Value Mapping] iavm
                on
                    (
                        iav.company_id = iavm.company_id
                    and iav.[Attribute ID] = iavm.[Item Attribute ID]
                    and iav.ID = iavm.[Item Attribute Value ID]
                    )
                where
                    (
                        ia.[Name] = 'Item Budget Group'
                    and ia.company_id = i.company_id
                    and iavm.No_ = i.No_
                    )
            ) cat
        outer apply
            (
                select top 1
                    (iav.company_id*10000)+iav.ID parent_category_id
                    from
                        hs_consolidated.[Item Attribute] ia
                    join
                        hs_consolidated.[Item Attribute Value] iav
                    on
                        (
                            ia.company_id = iav.company_id
                        and ia.ID = iav.[Attribute ID]
                        )  
                    where
                        (
                            ia.[Name] = 'Item Budget Group'
                        and nullif(iav.[Value],'') is null
                        and ia.company_id = i.company_id
                        )
            ) cat_none
        where
            (
                i.company_id = 1
            and ii.[Type] = 0
            and ii.[Inventory Posting Group] = 'FINISHED'
            and 
                (
                    i.lastOrder >= datefromparts(year(getutcdate()),1,1)
                or  i.lastOrder is null
                )
            and ii.[Status] != 3
            )
    )
, range_dist as
    (
        select
            ibg,
            rc,
            db_sys.fn_divide(sum(dr) over (partition by ibg, rc),sum(dr) over (partition by ibg),0) dist
        from
            x
    )

select
    x.sku [Item Code],
    x.rc [Current Range Code], 
    y.rc [Recommended Range Code]
from
    x
join
    range_dist rd
on
    (
        x.ibg = rd.ibg
    and x.rc = rd.rc
    )
cross apply
    (
        select top 1 dist, rc from range_dist rd where rd.ibg = x.ibg order by dist desc
    ) y
where
    (
        rd.dist < y.dist
    )
GO
