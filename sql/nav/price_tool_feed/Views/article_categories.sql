CREATE view [price_tool_feed].[article_categories]

as

with x as
    (
        select
            isnull(cat.parent_category_id,cat_none.parent_category_id) ibg,
            r.ID range_id,
            ii.No_ sku,
            dense_rank() over (partition by isnull(cat.parent_category_id,cat_none.parent_category_id) order by r.ID) dr
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
            ext.[Range] r
        on
            (
                ii.company_id = r.company_id
            and ii.[Range Code] = r.range_code
            )
        join
            hs_consolidated.[Sales & Receivables Setup] srs
        on
            (
                ii.company_id = srs.company_id
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
                    iav.ID parent_category_id
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
                    iav.ID parent_category_id
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
            and ii.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
            and i.ID in (select article_id from price_tool_feed.sales_all)
            )
    )
, range_dist as
    (
        select
            ibg,
            range_id,
            db_sys.fn_divide(sum(dr) over (partition by ibg, range_id),sum(dr) over (partition by ibg),0) dist
        from
            x
    )

select distinct
    range_id category_id,
    h.[Description] [name],
    null parent_id
from
    (
        select distinct
            range_id
        from
            range_dist
    ) rd
join
    ext.[Range] e
on
    (
        rd.range_id = e.ID 
    )
join
    hs_consolidated.[Range] h
on
    (
        e.company_id = h.company_id
    and e.range_code = h.[Code]
    )

union all

select
    10000+x.ibg,
    isnull(nullif(att.[name],''),'(blank)'),
    y.range_id
from
    (
        select 
            ibg 
        from 
            range_dist 
        group by ibg
    ) x
join
    (
        select
            iav.ID ibg,
            iav.[Value] [name]
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
            ia.company_id = 1

    ) att
on
    (
        x.ibg = att.ibg
    )
cross apply
    (
        select top 1 range_id from range_dist rd where x.ibg = rd.ibg order by dist desc
    ) y
GO
