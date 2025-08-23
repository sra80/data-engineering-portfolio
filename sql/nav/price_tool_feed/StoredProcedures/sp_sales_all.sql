create or alter procedure [price_tool_feed].[sp_sales_all]

as

set nocount on

declare @t table (id int, batch_id uniqueidentifier)

declare @batch_id uniqueidentifier

insert into @t (id)
select
    id
from
    ext.Sales_Line_Archive l
join
    hs_consolidated.Item ii
on
    (
        l.company_id = ii.company_id
    and l.No_ = ii.No_
    )
where
    (
        l.company_id = 1
    and ii.[Type] = 0
    )

except

select
    id
from
    price_tool_feed.sales_all

while (select isnull(sum(1),0) from @t where batch_id is null) > 0

    begin /*678c*/

        set @batch_id = newid()

        update t set t.batch_id = @batch_id from (select top 1000 id, batch_id from @t where batch_id is null) t

        insert into price_tool_feed.sales_all (id, store_id, article_id, [date], price_type, quantity, price, shelf_price, cost_price, customer_id)
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
                    -- or  d.is_new_sub = 1 --commented out 20/05/2024 @ 13:59 EEST, agreed with Simon
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
            h.customer_id
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
                @t t
            on
                (
                    l.id = t.id
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
                and t.batch_id = @batch_id
                and ii.[Type] = 0
                )

    end /*678c*/

delete from @t

--amazon sales
insert into @t (id)
select
    al.sales_line_id
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
    finance.SalesInvoices_Amazon amz
on
    (
        ile.[Location Code] = amz.warehouse
    )
where
    (
        ile.[Entry Type] = 1
    and ile.[Document Type] = 0
    and i.[Type] = 0
    )

except

select
    id
from
    price_tool_feed.sales_all

while (select isnull(sum(1),0) from @t where batch_id is null) > 0

    begin /*366d*/

        set @batch_id = newid()

        update t set t.batch_id = @batch_id from (select top 1000 id, batch_id from @t where batch_id is null) t

        insert into price_tool_feed.sales_all (id, store_id, article_id, [date], price_type, quantity, price, shelf_price, cost_price, customer_id)
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
            @t t
        on
            (
                al.sales_line_id = t.id
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
            and t.batch_id = @batch_id
            )

    end /*366d*/
GO
