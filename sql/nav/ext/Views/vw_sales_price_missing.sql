create or alter view ext.vw_sales_price_missing

as

with x as
    (
        select
            op.item_id,
            sc.id cpg_id,
            row_number() over (partition by op.item_id order by sc.id) r,
            sum(1) over (partition by op.item_id) c,
            sc.code [Customer Price Group],
            ii.No_ [Item No],
            ii.[Description] [Item Description],
            lu._value [Item Status],
            i.lastOrder [Last Order],
            i.avg_price_single [AOV Single Purchase],
            i.avg_price_repeat [AOV Subscription],
            case 
                when fp.price is null  then concat('insert ''',sc.code,''' price')
                when fp.price = 0  then concat('Verify ''',sc.code,''' price of 0.00 is correct')
                when fp.end_date < datefromparts(2099,12,31) then concat('Add or extend ''',sc.code,''' price to 31/12/2099')
            end resolution
        from
            (
                select 
                    item_id,
                    sum(case when is_batch = 1 then open_balance else 0 end) stock
                from 
                    stock.oos_plr 
                where 
                    (
                        row_version = (select row_version from stock.forecast_subscriptions_version where is_current = 1)
                    and rv_sub = 0
                    and location_id in (select ID from ext.Location where default_loc = 1)
                    and forecast_close_bal < open_balance
                    )
                group by
                    item_id

            ) op
        join
            ext.Item i
        on
            (
                op.item_id = i.ID
            )
        join
            [dbo].[UK$Item] ii
        on
            (
                i.No_ = ii.No_
            )
        join
            db_sys.Lookup lu
        on
            (
                lu.tableName = 'UK$Item'
            and lu.columnName = 'Status'
            and lu._key = ii.[Status]
            )
        cross apply
            (
                select
                    id,
                    code,
                    is_ss
                from
                    ext.Customer_Price_Group
                where
                    check_missing = 1
            ) sc
        outer apply
            (
                select top 1
                    convert(money,sp.[Unit Price]) price,
                    sp.[Ending Date] end_date
                from
                    [dbo].[UK$Sales Price] sp
                where
                    (
                        sp.[Sales Code] = sc.code
                    and sp.[Item No_] = i.No_
                    and sp.[Ending Date] >= getutcdate()
                    )
                order by
                    sp.[Ending Date] desc
            ) fp
        where
            (
                ii.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
            and
                (
                    ii.Status = 0
                or  (
                        op.stock > 0
                    and (
                            (
                                i.avg_price_repeat is not null
                            and sc.is_ss = 1
                            ) 
                        or  (
                                i.avg_price_single is not null
                            and sc.is_ss = 0
                            )
                        )
                    )
                )
            and
                (
                    isnull(fp.end_date,getdate()) < datefromparts(2099,12,31)
                or  fp.price is null
                or  
                    (
                        fp.price = 0
                    and i.avg_price_single > 0
                    )
                )
            )
    )

select
    list.[Item No],
    list.[Item Description],
    list.[Last Order],
    list.[Item Status],
    list.[AOV Single Purchase],
    list.[AOV Subscription],
    concat(stuff(issue.resolution,1,1,upper(left(issue.resolution,1))),'.') [Recommendations]
from
    (
        select
            item_id,
            [Item No],
            [Item Description],
            [Item Status],
            [Last Order],
            [AOV Single Purchase],
            [AOV Subscription]
        from
            x
        where
            x.r = 1
    ) list
outer apply
    (
        select
            string_agg(resolution,', ') resolution
        from
            x
        where
            (
                list.item_id = x.item_id
            )
    ) issue