create or alter procedure ext.sp_sales_item_doubles

as

set nocount on

delete from ext.sales_item_doubles where order_date < datefromparts(year(getutcdate())-1,1,1)

declare @t table (sales_header_id int, order_date date, delivery_service_id int, delivery_service_line_id int, lines int, units_ttl int)

declare @rc int = 1

while @rc > 0

begin

insert into @t (sales_header_id, order_date, delivery_service_id, delivery_service_line_id)
select top 20000 
    h.id,
    h.[Order Date],
    isnull(ds.delivery_service_id,-1),
    isnull(ds.id,-1)
from 
    ext.Sales_Header_Archive h
outer apply
    (
        select top 1
            sla.id,
            e_ds.id delivery_service_id
        from
            ext.delivery_service e_ds
        join
            ext.Sales_Line_Archive sla
        on
            (
                e_ds.company_id = sla.company_id
            and e_ds.code = sla.[Delivery Service]
            )
        where
            (
                sla.sales_header_id = h.id
            )
    ) ds
where 
    (
        h.is_sid_processed = 0
    )

select @rc = isnull(sum(1),0) from @t

update
    t
set
    t.units_ttl = num.units_ttl,
    t.lines = num.lines
from
    @t t
cross apply
    (
        select
            sum(Quantity) units_ttl,
            sum(1) lines
        from
            (
                select
                    sales_header_id,
                    No_,
                    sum(Quantity) Quantity
                from
                    ext.Sales_Line_Archive
                where
                    (
                        Sales_Line_Archive.id != t.delivery_service_line_id
                    )
                group by
                    sales_header_id,
                    No_
            ) l
        where
            (
                t.sales_header_id = l.sales_header_id
            )
    ) num

update
    h
set
    h.is_sid_processed = 1
from
    ext.Sales_Header_Archive h
join
    @t t
on
    (
        h.id = t.sales_header_id
    )
where
    (
        t.units_ttl < 2
    )

delete from @t where units_ttl < 2

;with x as
    (
        select
            l.sales_header_id,
            l.item_id,
            sum(l.Quantity)/2 pair,
            sum(l.Quantity)%2 mod
        from
            (
                select
                    k.sales_header_id,
                    i.item_id,
                    k.Quantity
                from
                    @t t
                join
                    ext.Sales_Line_Archive k
                on
                    (
                        t.sales_header_id = k.sales_header_id
                    )
                join
                    (
                        select
                            e.company_id,
                            e.ID item_id,
                            e.No_
                        from
                            ext.Item e
                        join
                            hs_consolidated.Item h
                        on
                            (
                                e.company_id = h.company_id
                            and e.No_ = h.No_
                            )
                        where
                            (
                                h.[Type] = 0
                            )
                    ) i
                on
                    (
                        k.company_id = i.company_id
                    and k.No_ = i.No_
                    )
            ) l
        group by
            l.sales_header_id,
            l.item_id
    )


, y (sales_header_id, item_id_1, item_id_2, _count) as
    (
        select
            x.sales_header_id,
            x.item_id item_id_1,
            x.item_id item_id_2,
            x.pair _count
        from
            x
        where
            (
                pair > 0
            )

        union all

        select
            y.sales_header_id,
            y.item_id,
            z.item_id,
            1
        from
            x y
        cross apply
            (
                select
                    item_id,
                    mod
                from
                    x
                where
                    x.sales_header_id = y.sales_header_id
                and x.mod = 1
                and y.item_id > x.item_id
            ) z
        where
            (
                y.mod = 1
            )
    )

insert into ext.sales_item_doubles (sales_header_id, order_date, delivery_service_id, item_id_1, item_id_2, units_ttl, _count, is_parcel, is_largeletter)
select
    y.sales_header_id,
    t.order_date,
    t.delivery_service_id,
    y.item_id_1,
    y.item_id_2,
    t.units_ttl,
    y._count,
    isnull(is_parcel.is_true,0) is_parcel,
    isnull(is_largeletter.is_true,0) is_largeletter
from
    y
join
    @t t
on
    (
        y.sales_header_id = t.sales_header_id
    )
outer apply
    (
        select top 1
            1 is_true
        from
            hs_consolidated.[Item] i
        join
            ext.Item ii
        on
            (
                i.company_id = ii.company_id
            and i.No_ = ii.No_
            )
        where
            (
                i.[Packaging Type] = 'PARCEL'
            and 
                (
                    y.item_id_1 = ii.ID
                or  y.item_id_2 = ii.ID
                )
            )
    ) is_parcel
outer apply
    (
        select top 1
            1 is_true
        from
            hs_consolidated.[Item] i
        join
            ext.Item ii
        on
            (
                i.company_id = ii.company_id
            and i.No_ = ii.No_
            )
        where
            (
                i.[Packaging Type] = 'LARGELETTER'
            and 
                (
                    y.item_id_1 = ii.ID
                or  y.item_id_2 = ii.ID
                )
            )
    ) is_largeletter

update
    h
set
    h.is_sid_processed = 1
from
    ext.Sales_Header_Archive h
join
    @t t
on
    (
        h.id = t.sales_header_id
    )

delete from @t

end