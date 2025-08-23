create or alter procedure ext.sp_amazon_import_reconciliation

as

set nocount on

declare
    @auditLog_id int

select
    @auditLog_id = a.ID
from
    db_sys.auditLog a
where
    (
        a.place_holder = 
            (
                select top 1
                    place_holder
                from
                    db_sys.procedure_schedule
                where
                    procedureName = 'ext.sp_amazon_import_reconciliation'
            )
    )

if @auditLog_id >= 0

    begin

    insert into ext.amazon_import_recon_history (recon_auditLog_ID, sales_line_id, quantity, auditLog_ID)
    select
        l.recon_auditLog_ID,
        l.id,
        r.quantity,
        @auditLog_id
    from
        ext.amazon_import_reconciliation r
    join
        ext.amazon_import_sales_line l
    on
        (
            r.sales_line_id = l.id
        )
    join
        db_sys.auditLog a
    on
        (
            l.recon_auditLog_ID = a.ID
        )
    cross apply
        (
            select
                sum(1) c
            from
                ext.amazon_import_recon_history x
            where
                l.id = x.sales_line_id
        ) c
    where 
        (
            r.ile_entry_no = -1
            and
                (
                    (
                        datediff(day,r.addTS,getutcdate()) = 0
                    and isnull(c.c,0) < 5
                    )
                or
                    (
                        datediff(day,r.addTS,getutcdate()) > 0
                    and isnull(c.c,0) < 15
                    )
                )
        )

    delete from ext.amazon_import_reconciliation where sales_line_id in (select sales_line_id from ext.amazon_import_recon_history where auditLog_ID = @auditLog_id) and ile_entry_no = -1

    update l set l.recon_auditLog_ID = null from ext.amazon_import_sales_line l join ext.amazon_import_recon_history rh on (l.id = rh.sales_line_id) where rh.auditLog_ID = @auditLog_id

    end

declare @s table (id int, sales_header_id int, sku nvarchar(32), quantity_shipped int)

declare @t table (id int, entry_no int, quantity int)

while (select sum(1) from ext.amazon_import_sales_line where recon_auditLog_ID is null) > 0

    begin

        insert into @s (id, sales_header_id, sku, quantity_shipped)
        select top 20000
            l.id,
            l.sales_header_id,
            ext.fn_amazon_import_sku_nav(l.sku),
            l.quantity_shipped
        from
            ext.amazon_import_sales_line l
        where
            (
                l.recon_auditLog_ID is null
            )

        insert into @t (id, entry_no, quantity)
        select
            import.id,
            isnull(nav.entry_no,-1) entry_no,
            sum(1) quantity
        from
            (
                select
                    ext.fn_amazon_import_order_id_rev(h.amazon_order_id_p1, h.amazon_order_id_p2, h.amazon_order_id_p3) amazon_order_id,
                    l.sku,
                    l.id,
                    row_number() over (partition by h.id, l.sku order by l.id, it.iteration) -1 iteration
                from
                    [ext].[amazon_import_sales_header] h
                join
                    @s l
                on
                    (
                        h.id = l.sales_header_id
                    )
                cross apply
                    (
                        select
                            iteration
                        from
                            db_sys.iteration
                        where
                            iteration.iteration < l.quantity_shipped
                    ) it
            ) import
        outer apply
            (
                select
                    [Entry No_] entry_no,
                    ile.iteration
                from
                    (
                        select
                            [Entry No_],
                            row_number() over (partition by ile.[External Document No_], ile.[Location Code], ile.[Item No_] order by [Entry No_]) -1 iteration
                        from
                            [dbo].[UK$Item Ledger Entry] ile
                        join
                            [finance].[SalesInvoices_Amazon] sia
                        on
                            (
                                ile.[Location Code] = sia.warehouse
                            )
                        cross apply
                            (
                                select
                                    iteration
                                from
                                    db_sys.iteration
                                where
                                    iteration < abs(ile.Quantity)
                            ) it
                        where
                            (
                                ile.[External Document No_] = import.amazon_order_id
                            and ile.[Item No_] = import.sku
                            and ile.[Entry No_] not in (select ile_entry_no from ext.amazon_import_reconciliation)
                            )
                    ) ile
                where
                    (
                        import.iteration = ile.iteration
                    )
            ) nav
        group by
            import.id,
            nav.entry_no

        insert into ext.amazon_import_reconciliation (sales_line_id, ile_entry_no, quantity)
        select
            t.id,
            t.entry_no,
            t.quantity
        from
            @t t
        left join
            ext.amazon_import_reconciliation air
        on
            (
                t.id = air.sales_line_id
            and t.entry_no = air.ile_entry_no
            )
        where
            (
                air.sales_line_id is null
            and air.ile_entry_no is null
            )

        update
            l
        set
            l.recon_auditLog_ID = isnull(@auditLog_id,-1),
            l.recon_match_ratio = isnull(try_convert(decimal(3,2),round(db_sys.fn_divide(isnull(u.quantity,0),l.quantity_shipped,0),2)),9.99)
        from
            @s s
        join
            ext.amazon_import_sales_line l
        on
            (
                s.id = l.id
            )
        outer apply
            (
                select
                    sum(quantity) quantity
                from
                    @t t
                where
                    (
                        s.id = t.id
                    and t.entry_no >= 0
                    )
            ) u
        where
            (
                l.recon_auditLog_ID is null
            )

        delete from @s

        delete from @t

    end