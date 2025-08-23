create or alter procedure [ext].[sp_Item_firstOrder]

as

set nocount on

;with s as
	(
        select
            orders.company_id,
            orders.No_,
            min(orders.[Order Date]) firstOrder,
            max(orders.[Order Date]) lastOrder
        from
            (
                select 
                    h.company_id,
                    h.[Order Date],
                    l.No_
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

                union all
                
                select 
                    h.company_id,
                    h.[Order Date],
                    l.No_
                from
                    ext.Sales_Header h
                join
                    ext.Sales_Line l
                on
                    (
                        h.company_id = l.company_id
                    and h.No_ = l.[Document No_]
                    and h.[Document Type] = l.[Document Type]
                    )
                where
                    h.[Sales Order Status] = 1

                union all

                select
                    company_id,
                    _date,
                    (select No_ from ext.Item i where i.ID = a.sku)
                from
                    ext.Sales_Archive a

                union all

                select 
                    h.company_id,
                    h.[Order Date],
                    l.[BOM Item No_]
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

                union all
                
                select 
                    h.company_id,
                    h.[Order Date],
                    l.[BOM Item No_]
                from
                    ext.Sales_Header h
                join
                    ext.Sales_Line l
                on
                    (
                        h.company_id = l.company_id
                    and h.No_ = l.[Document No_]
                    and h.[Document Type] = l.[Document Type]
                    )
                where
                    h.[Sales Order Status] = 1
                
            ) orders
        where
            len(orders.No_) > 0
        group by
            orders.company_id,
            orders.[No_]
	)

merge ext.Item t
using s
on (t.company_id = s.company_id and t.No_ = s.No_)
when matched then update set
    t.firstOrder = (select min(x) from (values (s.firstOrder),(t.firstOrder)) as x(x)),
    t.lastOrder = (select max(x) from (values (s.lastOrder),(t.lastOrder)) as x(x))
when not matched by target then insert (company_id, No_, firstOrder, lastOrder) values (s.company_id, s.No_, s.firstOrder, s.lastOrder);
GO
