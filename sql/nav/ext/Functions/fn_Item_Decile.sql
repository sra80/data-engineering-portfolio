CREATE function ext.fn_Item_Decile
    (
        @item_id int = null,
        @date_from date = null,
        @date_to date = null
    )

returns table

as

return
select
    y.sku item_id,
    ceiling(y.x*10) decile
from
    (
        select
            x.sku,
            db_sys.fn_divide(sum(x.net_revenue) over (order by x.net_revenue desc rows between unbounded preceding and current row),sum(x.net_revenue) over (),0) x
        from
            (
                select
                    s.sku,
                    sum(s.net_revenue) net_revenue
                from
                    ext.Sales_Archive s
                join
                    ext.Channel c
                on
                    (
                        s.company_id = c.company_id
                    and s.channel = c.ID
                    )
                join
                    ext.Channel_Grouping cg
                on
                    (
                        c.Group_Code = cg.Code
                    )
                where 
                    (
                        s._date >= isnull(@date_from,dateadd(month,-12,getutcdate()))
                    and s._date <= isnull(@date_to,getutcdate())
                    and cg.[Description] != 'Intercompany'
                    )
                group by
                    s.sku
            ) x
    ) y
where
    (
        y.sku = isnull(@item_id,y.sku)
    )
GO
