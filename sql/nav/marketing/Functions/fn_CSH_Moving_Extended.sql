CREATE function [marketing].[fn_CSH_Moving_Extended]
    (
        @cus nvarchar(32),
        @date_start date,
        @date_end date
    )

returns table

as

/*
0 TB: Frequency >= 2.1 and Product Count > 2 (True Believer)
1 HE: Frequency < 2.1 and Product Count > 2 (Hesitant Experimenter)
2 TF: Frequency >= 2.1 and Product Count < 3 (Targeted Fixer)
3 PG: Frequency < 2.1 and Product Count < 3 (Pascal's Gambler)
*/

return

(

with 
opt_status as
    (
    select
        change_date,
        opt_in_status,
        opt_source
    from
        (
        select
            case [Status] when 0 then 1 else 0 end opt_in_status,
            convert(date,[Modified DateTime]) change_date,
            case when lag([Status]) over (order by [Modified DateTime]) = [Status] then 0 else 1 end state_change,
            [Modified DateTime],
            opt_source
        from
            (
            select 
                [Status], 
                [Modified DateTime],
                case when [Modified DateTime] = max([Modified DateTime]) over (partition by convert(date,[Modified DateTime])) then 1 else 0 end last_change,
                nullif(marketing.fn_csh_opt_source([Web Page URL]),'') opt_source
            from 
                [UK$Customer Preferences Log]
            where
                (
                    [Customer No_] = @cus
                -- and [Modified DateTime] >= @date_start  -- commented out, needs to be the last entry before end or on date_end
                and convert(date,[Modified DateTime]) <= isnull(@date_end,convert(date,getutcdate()))
                and [Record Code] = 'EMAIL'
                )
            ) cpl
        where
            cpl.last_change = 1
        ) n
    where
        (
            n.state_change = 1
        )
    )
,
sales as 
    (
    select 
        h.[Order Date] order_date,
        l.No_ sku,
        l.Quantity qty,
        null opt_in_status
    from
        ext.Sales_Header h
    join
        ext.Sales_Line l
    on
        (
            h.No_ = l.[Document No_]
        and h.[Document Type] = l.[Document Type]
        )
    join
        dbo.[UK$Item] i
    on
        (
            l.No_ = i.No_
        )
    where
        (
            h.[Sales Order Status] = 1
        and i.[Range Code] = 'VITSUP'
        and h.[Sell-to Customer No_] = @cus
        and h.[Order Date] >= dateadd(year,-1,@date_start)
        and h.[Order Date] <= isnull(@date_end,convert(date,getutcdate()))
        )

    union all

    select
        h.[Order Date] order_date,
        l.No_ sku,
        l.Quantity qty,
        null
    from
        ext.Sales_Header_Archive h
    join
        ext.Sales_Line_Archive l
    on
        (
            h.No_ = l.[Document No_]
        and h.[Document Type] = l.[Document Type]
        and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
        and h.[Version No_] = l.[Version No_]
        )
    join
        dbo.[UK$Item] i
    on
        (
            l.No_ = i.No_
        )
    where
        (
            i.[Range Code] = 'VITSUP'
        and h.[Sell-to Customer No_] = @cus
        and h.[Order Date] >= dateadd(year,-1,@date_start)
        and h.[Order Date] <= isnull(@date_end,convert(date,getutcdate()))
        )

    union all

    select
        @date_start,
        null,
        0,
        null

    union all
        
        select
            change_date,
            null,
            0,
            opt_in_status
        from
            opt_status

    )

select
    sub4.order_date _start_date,
    isnull(dateadd(day,-1,lead(sub4.order_date) over (order by sub4.order_date)),@date_end) _end_date,
    sub4.ecosystem,
    sub4.opt_in_status,
    case when sub4.opt_state_change = 1 then isnull(sub4.opt_source,'offline') end opt_source,
    sub4.eco_state_change,
    sub4.opt_state_change
from
    (
    select
        sub3.order_date,
        sub3.ecosystem,
        sub3.opt_in_status,
        sub3.opt_source,
        case when lag(sub3.ecosystem) over (order by sub3.order_date) = sub3.ecosystem then 0 else case when lag(sub3.order_date) over (order by sub3.order_date) is null or lag(sub3.order_date) over (order by sub3.order_date) < sub3.order_date then 1 else 0 end end eco_state_change,
        case when lag(sub3.opt_in_status) over (order by sub3.order_date) = sub3.opt_in_status then 0 else case when lag(sub3.order_date) over (order by sub3.order_date) is null or lag(sub3.order_date) over (order by sub3.order_date) < sub3.order_date then 1 else 0 end end opt_state_change
    from
        (
        select
            sub2.order_date,
            sub2.opt_in_status,
            sub2.opt_source,
            case when sub2.order_date < datefromparts(year(getdate())-1,1,1) then -1 else
                case 
                    when sub2.prod_freq >= 2.1 then
                        case when sub2.prod_count > 2 then 0 else 2 end
                    else 
                        case when sub2.prod_count > 2 then 1 else 3 end
                end 
            end ecosystem
        from
            (
            select
                sub1.order_date,
                sub1.opt_in_status,
                sub1.opt_source,
                db_sys.fn_divide(sub1.prod_qty,sub1.prod_count,default) prod_freq,
                sub1.prod_qty,
                sub1.prod_count
            from
                (
                select
                    isnull(sub0.order_date,opt_status.change_date) order_date,
                    isnull(opt_status.opt_in_status,0) opt_in_status,
                    opt_status.opt_source,
                    isnull(sub0.prod_count,0) prod_count,
                    isnull(sub0.prod_qty,0) prod_qty
                from
                    (
                    select 
                        sales_base.order_date,
                        count(distinct sales_cross.sku) prod_count,
                        sum(sales_cross.qty) prod_qty
                    from 
                        (select distinct order_date from sales) sales_base
                    cross apply
                        sales sales_cross
                    where
                        (
                            sales_cross.order_date >= dateadd(year,-1,sales_base.order_date) --
                        and sales_cross.order_date <= sales_base.order_date --
                        )
                    group by
                        sales_base.order_date
                    ) sub0
                outer apply
                    (select top 1 opt_in_status, change_date, opt_source from opt_status where change_date <= sub0.order_date order by change_date desc) opt_status
                ) sub1
            ) sub2
        ) sub3
    ) sub4
where
    (
        sub4.order_date = @date_start
    or        
        (
            sub4.order_date > @date_start
        and
            (
                sub4.eco_state_change = 1
            or  sub4.opt_state_change = 1
            )
        )
    )
)
GO
