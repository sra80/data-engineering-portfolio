create or alter function ext.fn_Item_Location_avg_sales
    (
        @item_id int,
        @location_id int
    )

returns table

as

return

select
    isnull(round(db_sys.fn_divide(sales_single,day_count,0),20),0) + isnull(round(db_sys.fn_divide(sales_repeat,day_count,0),20),0) sales_total,
    isnull(round(db_sys.fn_divide(sales_single,day_count,0),20),0) sales_single,
    isnull(round(db_sys.fn_divide(sales_repeat,day_count,0),20),0) sales_repeat
from
    (
        select
            datediff(day,min(d),max(d)) day_count,
            sum(sales_single) sales_single,
            sum(sales_repeat) sales_repeat
        from
            (
                select
                    cal.d,
                    isnull(ile.sales_single,0) sales_single,
                    isnull(ile.sales_repeat,0) sales_repeat
                from
                    (
                        select
                            dateadd(day,iteration,ds.date_start) d
                        from
                            db_sys.iteration
                        cross apply
                            (
                                select 
                                    max(convert(date,d)) date_start
                                from 
                                    (
                                        values
                                            (
                                                (
                                                    select 
                                                        min([Posting Date]) 
                                                    from 
                                                        hs_consolidated.[Item Ledger Entry] ile 
                                                    join 
                                                        anaplan.location_overide_aggregate loa 
                                                    on 
                                                        (
                                                            ile.company_id = loa.company_id 
                                                        and ile.[Location Code] = loa.location_code
                                                        ) 
                                                    where 
                                                        (
                                                            location_ID_overide = @location_id 
                                                        and ile.[Item No_] = (select No_ from ext.Item where ID = @item_id)
                                                        )
                                                    )
                                            ),
                                            (
                                                dateadd(day,-182,getutcdate())
                                            )
                                    ) as x(d)
                            ) ds
                        where
                            (
                                iteration <= datediff(day,ds.date_start,getutcdate())
                            )
                    ) cal
                left join
                    (
                        select 
                            [Posting Date],
                            sales_single,
                            sales_repeat
                        from
                            (
                                select
                                    company_id,
                                    [Location Code],
                                    [Posting Date],
                                    Quantity,
                                    case when len([Subscription No_]) = 0 then Quantity else 0 end sales_single,
                                    case when len([Subscription No_]) > 0 then Quantity else 0 end sales_repeat,
                                    percentile_cont(0.25) within group (order by Quantity) over () q_25,
                                    percentile_cont(0.75) within group (order by Quantity) over () q_75 
                                from
                                    hs_consolidated.[Item Ledger Entry]
                                where
                                    (
                                        [Item No_] = (select No_ from ext.Item where ID = @item_id)
                                    and [Entry Type] = 1
                                    and [Positive] = 0
                                    )
                                ) ile
                        join
                            anaplan.location_overide_aggregate loa
                        on
                            (
                                ile.company_id = loa.company_id
                            and ile.[Location Code] = loa.location_code
                            )
                        where 
                            (
                                loa.location_ID_overide = @location_id
                            and ile.Quantity >= ile.q_25
                            and ile.Quantity <= ile.q_75
                            )
                    ) ile
                on
                    (
                        cal.d = ile.[Posting Date]
                    )
            ) ile
    ) x