create or alter view [price_tool_feed].[articles]

as

select
   i.ID article_id,
    concat(coalesce(nullif(ii.[Description 2],''),nullif(ii.[Description],''),'No Name'),' (',ii.No_,')') [name],
    case ii.[Status]
        when 0 then 2
        when 1 then 2
        when 2 then 9
        when 3 then 9
        when 4 then
            case when stock.qty > 0 then 2 else 6 end --in NAV 4 = Rundown, in Yieldigo, 6 = Discontinued, agreed to adopt 'End of Life' conditions (product is in Rundown and is out of stock)
        when 5 then 9
    end [status],
    cat.parent_category_id parent_category_id,
    convert(decimal(3,1),round(isnull(vps.[VAT _],0),2)) vat,
    ceiling(db_sys.fn_divide(ii.[Pack Size],ii.[Daily Dose],0)) unit_size,
    1 unit_count,
    'days' unit,
    convert(float,ii.[Daily Dose]) dosage,
    convert(float,ii.[Pack Size]) pack_size,
    ceiling(isnull(stock.qty,0)) [stock]
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
cross apply
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
            [Available Quantity] qty
        from
            [UK$Outbound Stock] os
        where
            (
                os.[Integration Code] = 'TRADEIT-UK'
            and os.[Activity] = 2
            and os.[Item No_] = i.No_
            and nullif(os.[Variant Code],'') is null
            and os.[Location Code] = 'WASDSP'
            )
        order by
            [Timestamp Date Time] desc
    ) stock
where
    (
        i.company_id = 1
    and ii.[Type] = 0
    and ii.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
    and     
        (
            i.ID in (select article_id from price_tool_feed.sales_all)
        or  i.No_ in (select [BOM Item No_] from ext.Sales_Line_Archive)
        )
    and
        ii.[Range Code] in (select range_code from ext.Range where is_inc_yieldigo = 1)
    )
GO
