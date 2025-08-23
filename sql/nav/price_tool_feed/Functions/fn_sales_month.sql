create function [price_tool_feed].[fn_sales_month]
    (
        @year int,
        @month int
    )

returns table

as

return

select
    l.id,
    d.store_id,
    i.ID article_id,
    convert(date,h.[Order Date]) [date],
    case when 
        convert(money,round(db_sys.fn_divide(l.[Amount Including VAT],l.Quantity,0),2)) < d.fullprice 
    then 
        case when 
            (
                l.[Promotion Discount Amount] > 0
            or  d.is_new_sub = 1
            )
        then
            3
        else
            2
        end
    else
        0
    end price_type,
    l.Quantity quantity,
    convert(money,round(db_sys.fn_divide(l.[Amount Including VAT],l.Quantity,0),2)) price,
    d.shelf_price,
    d.cost_price,
    hs_identity.fn_Customer(h.company_id,h.[Sell-to Customer No_]) customer_id
from
    ext.Sales_Header_Archive h
join
    ext.Sales_Line_Archive l
on
        (
            h.company_id = l.company_id
        and h.No_ = l.[Document No_]
        and h.[Document Type] = l.[Document Type]
        and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
        and h.[Version No_] = l.[Version No_]
        )
    join
        ext.Item i
    on
        (
            l.company_id = i.company_id
        and l.No_ = i.No_
        )
    join
        hs_consolidated.Item ii
    on
        (
            i.company_id = ii.company_id
        and i.No_ = ii.No_
        )
    cross apply
        price_tool_feed.fn_sales_details(h.[Channel Code],h.No_,h.[Inbound Integration Code],h.[Sell-to Customer No_],h.[Order Date],l.No_,h.customer_id) d
    where
        (
            h.company_id = 1
        and ii.[Type] = 0
        and eomonth(h.[Order Date]) = eomonth(datefromparts(@year,@month,1))
        )

    union all

    select
            al.sales_line_id,
            d.store_id,
            ii.ID article_id,
            convert(date,ile.[Document Date]),
            case when 
                convert(money,round(-db_sys.fn_divide(ve.amt_gros,ile.Quantity,0),2)) < d.fullprice 
            then 
                case when 
                    (
                        ve.amt_dis_promo > 0
                    or  d.is_new_sub = 1
                    )
                then
                    3
                else
                    2
                end
            else
                0
            end price_type,
            -ile.Quantity quantity,
            -db_sys.fn_divide(ve.amt_gros,ile.Quantity,0) price,
            d.shelf_price,
            d.cost_price,
            amz.customer_id
        from
            [dbo].[UK$Item Ledger Entry] ile
        join
            ext.Sales_Line_Amazon al
        on
            (
                ile.[Entry No_] = al.ile_entry_no
            )
        join
            [dbo].[UK$Item] i
        on
            (
                ile.[Item No_] = i.[No_]
            )
        join
            ext.Item ii
        on
            (
                ii.company_id = 1
            and i.No_ = ii.No_
            )
        join
            finance.SalesInvoices_Amazon amz
        on
            (
                ile.[Location Code] = amz.warehouse
            )
        join 
                (
                    select 
                        [Item Ledger Entry No_],
                        sum([Discount Amount]) amt_dis_promo,
                        sum([Sales Amount (Actual)]) amt_gros
                    from 
                        [dbo].[UK$Value Entry] x
                    group by 
                        [Item Ledger Entry No_]
                        
                ) ve
        on 
            ile.[Entry No_] = ve.[Item Ledger Entry No_]
        left join
                (
                    select
                        i.[No_],
                        d.[Ship-to Country_Region Code],
                        v.[VAT Bus_ Posting Group],
                        v.[VAT Prod_ Posting Group],
                        (v.[VAT _]/100)+1 [VAT Rate]
                    from
                        [dbo].[UK$Item] i 
                    join
                        [dbo].[UK$VAT Posting Setup] v
                    on
                        i.[VAT Prod_ Posting Group] = v.[VAT Prod_ Posting Group]
                    join
                        [dbo].[UK$Distance Sale VAT] d 
                    on
                        v.[VAT Bus_ Posting Group] = d.[VAT Bus_ Posting Group]	
                    where
                        d.[Location Code] = 'WASDSP'
                    and d.[VAT Bus_ Posting Group] <> 'STD'
                    ) v 
        on
            (
                ile.[Item No_] = v.[No_]
            and ile.[Country_Region Code] = v.[Ship-to Country_Region Code]
            )
        cross apply
            price_tool_feed.fn_sales_details(amz.channel_code,null,null,amz.cus_code,ile.[Document Date],ile.[Item No_],amz.customer_id) d
        where
            (
                ile.[Entry Type] = 1
            and ile.[Document Type] = 0
            and i.[Type] = 0
            and eomonth(ile.[Document Date]) = eomonth(datefromparts(@year,@month,1))
            )
GO
