create or alter procedure [stock].[sp_oos_plr]
    (
        @item_id int,
        @test bit = 0,
        @row_version int = -1
    )

as

set nocount on

/*
notes
- each begin and end has a pairing key e.g. b109, this is to make it easier to navigate through the script
*/

select
    @item_id = min(x1.ID)
from
    ext.Item x0
join
    ext.Item x1
on
    (
        x0.No_ = x1.No_
    )
where
    (
        x0.ID = @item_id
    ) 

declare 
    @date_close date = getutcdate(),
    @sku nvarchar(20) = (select top 1 No_ from ext.Item where ID = @item_id),
    @end_date_oos date = datefromparts(year(getutcdate())+1,12,31),
    @end_date_subs date = datefromparts(year(getutcdate())+3,12,31),
    @erd date,
    @is_original bit = 1

if @test = 0

    begin --b109

        if @row_version = -1

            begin --ad82

                set @is_original = 0

                select @row_version = row_version from stock.forecast_subscriptions_version where is_current = 1
                    
                update stock.oos_plr set rv_sub = rv_sub - 1 where item_id = @item_id and row_version = @row_version

                insert into stock.oos_plr_queue (item_id)
                select
                    op.item_id
                from
                    [hs_consolidated].[Purchase Header] ph
                join
                    [hs_consolidated].[Purchase Line] pl
                on
                    (
                        ph.company_id = pl.company_id
                    and ph.[Document Type] = pl.[Document Type]
                    and ph.[No_] = pl.[Document No_]
                    )
                join
                    ext.Purchase_Line e_pl
                on
                    (
                        pl.company_id = e_pl.company_id
                    and pl.[Document Type] = e_pl.[Document Type]
                    and pl.[Document No_] = e_pl.[Document No_]
                    and pl.[Line No_] = e_pl.[Line No_]
                    )
                join
                    stock.oos_plr op
                on
                    (
                        op.ref = e_pl.ID
                    )
            where
                    (
                        pl.No_ = @sku
                    and op.is_po = 1
                    and op.rv_sub = 0
                    and op.is_oos = 0
                    and op.row_version = @row_version
                    and op.item_id not in (select item_id from stock.oos_plr_queue)
                    )

                update
                    op
                set
                    op.rv_sub = op.rv_sub - 1
                from
                    [hs_consolidated].[Purchase Header] ph
                join
                    [hs_consolidated].[Purchase Line] pl
                on
                    (
                        ph.company_id = pl.company_id
                    and ph.[Document Type] = pl.[Document Type]
                    and ph.[No_] = pl.[Document No_]
                    )
                join
                    ext.Purchase_Line e_pl
                on
                    (
                        pl.company_id = e_pl.company_id
                    and pl.[Document Type] = e_pl.[Document Type]
                    and pl.[Document No_] = e_pl.[Document No_]
                    and pl.[Line No_] = e_pl.[Line No_]
                    )
                join
                    stock.oos_plr op
                on
                    (
                        op.ref = e_pl.ID
                    )
            where
                    (
                        pl.No_ = @sku
                    and op.is_po = 1
                    and op.row_version = @row_version
                    and op.item_id != @item_id
                    )

                update stock.oos_plr_log set rv_sub = rv_sub - 1 where item_id = @item_id and row_version = @row_version

                update stock.forecast_subscriptions set rv_sub = rv_sub - 1 where item_id = @item_id and row_version = @row_version

            end --ad82

        insert into stock.oos_plr_log (item_id, row_version) values (@item_id, @row_version)

    end --b109

declare @oos_plr table 
    (
        id int,
        location_id int,
        is_batch bit default 0,
        is_po bit default 0,
        is_po_1 bit default 0, --used to pick the first po in cases where there are multiple POs arrving in the same week (looks at the original erd without buffering)
        is_to bit default 0, --transfer order
        is_qa bit default 0,
        is_stop bit default 0,
        is_actual bit default 0,
        is_oos bit default 0,
        ref int,
        ldd date,
        erd date, --expected receipt date
        sale_first date,
        sale_last date,
        sales_2day int default 0,
        sale_total int default 0,
        subs_total int default 0,
        open_balance int default 0,
        avail_balance int default 0,
        ring_fenced int default 0,
        not_rf_subs_reserve int default 0,
        subs_overdue int default 0,
        sub_out_6m_scope int default 0,
        sub_b4_erd int default 0,
        rf_deadline date,
        rf_item_card date,
        rf_runout date,
        on_order int default 0,
        estimated_lost_subs int default 0,
        estimate_cycle int default 0,
        estimate_daily_sales decimal(28,10),
        estimate_daily_sales2 decimal(28,10),
        estimate_total_sales int,
        estimate_total_sales2 int,
        estimate_close_bal int default 0,
        estimate_close_bal2 int, --in cases where estimate_close_bal > 0, subs beyond initially reserved 6 month window are assigned to the batch, up to where ndd < ldd, close_bal less these assigned subs is stored in this column
        estimate_open_date date,
        estimate_close_date date,
        forecast_cycle int default 0,
        forecast_daily_sales decimal(28,10),
        forecast_daily_sales2 decimal(28,10),
        forecast_total_sales int,
        forecast_total_sales2 int,
        forecast_close_bal int default 0,
        forecast_close_bal2 int, --in cases where forecast_close_bal > 0, subs beyond initially reserved 6 month window are assigned to the batch, up to where ndd < ldd, close_bal less these assigned subs is stored in this column
        forecast_open_date date,
        forecast_close_date date,
        is_end bit default 0,
        is_eof bit default 0 -- end of forecast
    )

declare 
    @end_subs_res date = dateadd(month,6,@date_close)

declare @rf_item_card table (location_id int, rf_item_card date)

insert into @rf_item_card (location_id, rf_item_card) 
select
    (select top 1 ID from ext.Location l where l.company_id = Item.company_id and l.subscription_loc = 1),
    nullif([Ring Fencing Until Date],datefromparts(1753,1,1))
from 
    hs_consolidated.[Item]
where
    (
        No_ = @sku
    and [Ring Fencing Until Date] > @date_close
    )

declare @l table (location_id int, company_id int, grp int, estimate_daily_sales decimal(28,10), location_id_dist int, subscription_loc bit)

insert into @l (location_id, company_id, grp, estimate_daily_sales, location_id_dist, subscription_loc)
select
    x.ID,
    x.company_id,
    x.grp,
    coalesce(nullif(dl.estimate_daily_sales,0),nullif(ds.estimate_daily_sales,0),nullif(stock.fn_estimate_daily_sales(@item_id,loa.location_ID_overide),0),0) estimate_daily_sales,
    loa.location_ID_overide,
    x.subscription_loc
from
    (
        select
            ID,
            company_id,
            distribution_loc,
            holding_loc,
            subscription_loc,
            dense_rank() over (order by company_id, country, distribution_type) grp,
            country,
            distribution_type
        from
            ext.Location
    ) x
outer apply
    (
        select top 1
            ID location_id,
            stock.fn_estimate_daily_sales(@item_id,j.ID) estimate_daily_sales
        from
            ext.Location j
        where
            (
                x.company_id = j.company_id
            and x.country = j.country
            and x.distribution_type = j.distribution_type
            and j.default_loc = 1
            )
    ) dl
outer apply
    (
        select top 1
            ID location_id,
            stock.fn_estimate_daily_sales(@item_id,j.ID) estimate_daily_sales
        from
            ext.Location j
        where
            (
                x.company_id = j.company_id
            and x.country = j.country
            and x.distribution_type = j.distribution_type
            and j.distribution_loc = 1
            )
    ) ds
join
    anaplan.location_overide_aggregate loa
on
    (
        isnull(dl.location_id,ds.location_id) = loa.location_id
    )

declare @id int, @location_id int, @location_id_previous int, @ref int, @ldd date, @sale_first date, @avail_balance int, @reserved_stock int, @sale_total int, @sub_out_6m_scope int, @sub_b4_erd int

declare @estimate_daily_sales decimal(28,10), @estimate_total_sales decimal(28,10), @estimate_close_bal decimal(28,10), @estimate_open_date date, @estimate_close_date date, @estimate_cycle int, @estimate_batch_overflow decimal(28,10) = 0

declare @forecast_daily_sales decimal(28,10), @forecast_total_sales decimal(28,10), @forecast_close_bal decimal(28,10), @forecast_open_date date, @forecast_close_date date, @forecast_cycle int, @forecast_batch_overflow decimal(28,10) = 0, @is_eof bit = 0

insert into @oos_plr (id, location_id, is_batch, is_po, is_po_1, is_to, is_qa, is_stop, ref, ldd, open_balance, avail_balance, estimate_daily_sales, erd, sale_first, sale_last, sale_total, sales_2day, subs_total)
select
    100 + row_number() over (order by x.location_id, is_batch desc, is_to desc, is_po desc, is_qa, is_stop, (select min(d) from (values (ldd),(erd_order)/*,(sale_first)*/) as x(d)), x.open_balance) * 10,
    x.location_id,
    x.is_batch,
    x.is_po,
    case when x.is_po = 1 and row_number() over (partition by x.location_id, x.erd order by x.erd_order) = 1 then 1 else 0 end is_po_1,
    x.is_to,
    x.is_qa,
    x.is_stop,
    x.ref,
    isnull(x.ldd,datefromparts(2099,12,31)),
    x.open_balance,
    x.open_balance,
    x.estimate_daily_sales,
    x.erd,
    x.sale_first,
    x.sale_last,
    isnull(x.sale_total,0),
    isnull(x.sales_2day,0),
    isnull(x.subs_total,0)
from
    (
        select
            ob.location_id,
            1 is_batch,
            0 is_po,
            0 is_to,
            qas.is_qa,
            qas.is_stop,
            ob.ref,
            ob.open_balance,
            ext.fn_Item_Lifetime_ldd(ob.ref) ldd,
            case when ob.open_balance > 0 then qas.expected_release else null end erd,
            case when ob.open_balance > 0 then qas.expected_release else null end erd_order,
            ob.sale_first,
            ob.sale_last,
            ob.sale_total,
            ob.sales_2day,
            ob.subs_total,
            l.estimate_daily_sales
        from
            (
                select
                    ile.ref,
                    ile.location_id,
                    ile.open_balance,
                    ile.sale_first,
                    ile.sale_last,
                    ile.sale_total,
                    ile.sales_2day,
                    ile.subs_total
                from
                    (
                        select
                            l.location_id_dist location_id,
                            isnull(ibi.ref,no_batch.ref) ref,
                            min(case when [Entry Type] = 1 and nullif(ile.[Subscription No_],'') is null then ile.[Posting Date] end) sale_first,
                            max(case when [Entry Type] = 1 and nullif(ile.[Subscription No_],'') is null then ile.[Posting Date] end) sale_last,
                            sum(case when [Entry Type] = 1 and nullif(ile.[Subscription No_],'') is null then ile.[Quantity] end) sale_total,
                            sum(case when [Entry Type] = 1 and nullif(ile.[Subscription No_],'') is null and convert(date,ile.[Posting Date]) = @date_close then ile.[Quantity] end) sales_2day,
                            sum(case when [Entry Type] = 1 and len(ile.[Subscription No_]) > 0 then ile.[Quantity] end) subs_total,
                            sum(ile.Quantity) open_balance
                        from
                            hs_consolidated.[Item Ledger Entry] ile
                        join
                            ext.Location el
                        on
                            (
                                ile.company_id = el.company_id
                            and ile.[Location Code] = el.location_code
                            and
                                (
                                    el.distribution_loc = 1
                                or  el.holding_loc = 1
                                or  el.subscription_loc = 1
                                or  el.default_loc = 1
                                )
                            )
                        join
                            @l l
                        on
                            (
                                el.ID = l.location_id
                            )
                        join
                            hs_consolidated.[Location] hl
                        on
                            (
                                ile.company_id = hl.company_id
                            and ile.[Location Code] = hl.Code
                            )
                        left join
                            (
                                select 
                                    ID ref,
                                    company_id,
                                    sku,
                                    variant_code,
                                    batch_no,
                                    ldd
                                from 
                                    ext.Item_Batch_Info
                            ) ibi
                        on
                            (
                                ile.company_id = ibi.company_id
                            and ile.[Item No_] = ibi.sku
                            and ile.[Variant Code] = ibi.variant_code
                            and ile.[Lot No_] = ibi.batch_no
                            )
                        outer apply
                            (
                                select top 1
                                    ID ref
                                from
                                    ext.Item_Batch_Info xibi
                                where
                                    (
                                        xibi.company_id = ile.company_id
                                    and xibi.sku = ile.[Item No_]
                                    and xibi.variant_code = 'dummy'
                                    and xibi.batch_no = 'Not Provided'
                                    )
                            ) no_batch
                        where
                            (
                                ile.[Item No_] = @sku
                            and ile.[Posting Date] <= @date_close
                            and hl.[Skip Lot No_ Check] = 0
                            )
                        group by
                            l.location_id_dist,
                            isnull(ibi.ref,no_batch.ref)
                    ) ile
            ) ob
        join
            @l l
        on
            (
                ob.location_id = l.location_id_dist
            and l.location_id_dist = l.location_id
            )
        cross apply
            stock.fn_qa_status(ob.ref) qas
        where
            (
                (
                    ob.open_balance = 0
                and ob.sale_first is not null
                )
            or
                (
                    ob.open_balance > 0
                )
            )

        union all

        select
            l1.location_id_dist,
            0 is_batch,
            1 is_po,
            doc_type.is_to,
            0 is_qa,
            0 is_stop,
            e_pl.ID ref,
            pl.[Outstanding Quantity] open_balance,
            datefromparts(2099,12,31) ldd,
            dateadd(day,5,db_sys.foweek(pl.[Expected Receipt Date],case when hi.[Range Code] = 'ELITE' and doc_type.is_to = 0 then 3 when l0.distribution_loc = 1 then 0 else 1 end)) erd,
            pl.[Expected Receipt Date] erd_order,
            null sale_first,
            null sale_last,
            0 sale_total,
            0 sales_2day,
            0 subs_total,
            l2.estimate_daily_sales
        from
            [hs_consolidated].[Purchase Header] ph
        join
            [hs_consolidated].[Purchase Line] pl
        on
            (
                ph.company_id = pl.company_id
            and ph.[Document Type] = pl.[Document Type]
            and ph.[No_] = pl.[Document No_]
            )
        join
            ext.Purchase_Line e_pl
        on
            (
                pl.company_id = e_pl.company_id
            and pl.[Document Type] = e_pl.[Document Type]
            and pl.[Document No_] = e_pl.[Document No_]
            and pl.[Line No_] = e_pl.[Line No_]
            )
        join
            [hs_consolidated].[Vendor] v
        on
            (
                ph.company_id = v.company_id
            and ph.[Buy-from Vendor No_] = v.[No_]
            )
        join
            hs_consolidated.Item hi
        on
            (
                pl.company_id = hi.company_id
            and pl.[No_] = hi.[No_]
            )
        join
            ext.Location l0
        on
            (
                pl.company_id = l0.company_id
            and pl.[Location Code] = l0.location_code
            )
        join
            @l l1
        on
            (
                l0.ID = l1.location_id
            )
        join
            @l l2
        on
            (
                l1.location_id_dist = l2.location_id_dist
            and l2.location_id_dist = l2.location_id
            )
        cross apply
            (
                select
                    case when
                        (
                            v.company_id > 1
                        and v.[IC Partner Code] = 'HS SELL'
                        )
                    then
                        1
                    else
                        0
                    end is_to
            ) doc_type
       where
            (
                ph.[Document Type] = 1
            and ph.[Status] in (1,2,3)
            and ph.[Status 2] < 5
            and (
                    (
                        v.company_id = 1
                    and v.[Type of Supply Code] = 'PROCUREMNT'
                    )
                or
                    (
                        v.company_id > 1
                    and v.[IC Partner Code] = 'HS SELL'
                    )
                )
            and pl.No_ = @sku
            and pl.[Type] = 2
            and pl.[Outstanding Quantity] > 0
            and pl.[Expected Receipt Date] >=  db_sys.foweek(@date_close,0)
            )

        union all

        select
            l1.location_id_dist,
            0 is_batch,
            0 is_po,
            1 is_to,
            0 is_qa,
            0 is_stop,
            e_tl.ID ref,
            tl.[Quantity] open_balance,
            datefromparts(2099,12,31) ldd,
            dateadd(day,5,db_sys.foweek((select max(x.d) from (values(tl.[Receipt Date]),(@date_close)) as x(d)),case when ii.[Range Code] = 'ELITE' then 3 when l0.distribution_loc = 1 then 0 else 1 end)) erd,
            tl.[Receipt Date] erd_order,
            null sale_first,
            null sale_last,
            0 sale_total,
            0 sales_2day,
            0 subs_total,
            l2.estimate_daily_sales
        from
            [hs_consolidated].[Transfer Header] th
        join
            [hs_consolidated].[Transfer Line] tl
        on
            (
                th.company_id = tl.company_id
            and th.[No_] = tl.[Document No_]
            )
        join
            ext.Transfer_Line e_tl
        on
            (
                tl.company_id = e_tl.company_id
            and tl.[Document No_] = e_tl.[Document No_]
            and tl.[Line No_] = e_tl.[Line No_]
            )
        join
            [dbo].[UK$Item] ii
        on
            (
                tl.[Item No_] = ii.No_
            )
        join
            ext.Location l0
        on
            (
                tl.company_id = l0.company_id
            and th.[Transfer-to Code] = l0.location_code
            )
        join
            @l l1
        on
            (
                l0.ID = l1.location_id
            )
        join
            @l l2
        on
            (
                l1.location_id_dist = l2.location_id_dist
            and l2.location_id_dist = l2.location_id
            )
        left join
            (
                select 
                    trh.[Transfer Order No_],
                    trl.[Line No_],
                    trl.[Quantity]
                from
                    [hs_consolidated].[Transfer Receipt Header] trh
                join
                    [hs_consolidated].[Transfer Receipt Line] trl
                on
                    (
                        trh.company_id = trl.company_id
                    and trh.[No_] = trl.[Document No_]
                    )
                where
                    [Quantity] > 0
            ) tr
        on
            (
                tr.[Transfer Order No_] = th.[No_]
            and tr.[Line No_] = tl.[Line No_]
            )
        where
            (
                tl.[In-Transit Code] = 'IN TRANSIT'
            and tl.[Quantity] > tl.[Quantity Received]
            and tl.[Qty_ to Ship] = 0
            and tl.[Quantity Shipped] > 0
            and tl.[Item No_] = @sku
            )
    ) x

--subs, ring-fencing, outstanding orders
declare @queue table 
    (
        id int identity,
        location_id int,
        ndd date,
        is_priority bit default 0,
        is_rf bit default 0,
        is_overdue bit default 0,
        is_oo bit default 0,
        ref int,
        is_po bit default 0,
        is_to bit default 0,
        erd date, ldd date,
        is_bis bit default 0,
        portion float,
        ref2 int,
        is_po2 bit default 0,
        is_to2 bit default 0,
        erd2 date,
        ldd2 date,
        ref3 int,
        is_po3 bit default 0,
        is_to3 bit default 0,
        erd3 date,
        ldd3 date
    )

insert into @queue (location_id, ndd, is_priority, is_rf, is_overdue)
select
    (select top 1 location_id_dist from @l loc where loc.company_id = l.company_id and subscription_loc = 1) location_id,
    dateadd(day,(l.[Frequency (No_ of Days)]*ndd.iteration),l.ndd) ndd,
    case when (l.[Status] = 6 and ndd.iteration = 0) or rf.is_priority = 1 then 1 else 0 end is_priority, --ring fenced or overdue,
    isnull(rf.is_rf,0),
    case when ndd.iteration = 0 then l.is_overdue else 0 end is_overdue
from
    (
        select
            1 company_id,
            x.[Subscription No_],
            x.[Item No_],
            x.[Frequency (No_ of Days)],
            case when ext.fn_subscription_date_move(1,x.[Next Delivery Date]) < @date_close then @date_close else ext.fn_subscription_date_move(1,x.[Next Delivery Date]) end ndd,
            case when ext.fn_subscription_date_move(1,x.[Next Delivery Date]) < @date_close then 1 else 0 end is_overdue,
            x.[Quantity] * isnull(bc.[Quantity per],1) [Quantity],
            x.[Status]
        from
            [dbo].[UK$Subscriptions Line] x
        left join
            [dbo].[UK$BOM Component] bc
        on
            (
                x.[Item No_] = bc.[Parent Item No_]
            )
        outer apply
            (
                select top 1
                    sale_last
                from
                    @oos_plr
                where
                    (
                        location_id = (select top 1 location_id_dist from @l where company_id = 1 and subscription_loc = 1)
                    )
                order by
                    sale_last desc
            ) sale_last0
        outer apply
            (
                select top 1
                    nx.sale_last
                from
                    stock.oos_plr nx
                where
                    (
                        nx.item_id = @item_id
                    and nx.is_batch = 1
                    and nx.is_po = 0
                    and nx.is_to = 0
                    and nx.is_oos = 0
                    and nx.is_qa = 0
                    and nx.is_stop = 0
                    and nx.location_id = (select top 1 location_id_dist from @l where company_id = 1 and subscription_loc = 1)
                    )
                order by
                    row_version desc,
                    sale_last desc
            ) sale_last1
        where
            (
                ext.fn_subscription_date_move(1,x.[Next Delivery Date]) >= dateadd(month,-1,isnull(sale_last0.sale_last,sale_last1.sale_last))
            and x.[Status] in (0,6)
            and x.[Frequency (No_ of Days)] > 0
            and isnull(bc.[No_],x.[Item No_]) = @sku
            )

        union all

        select
            6 company_id,
            x.[Subscription No_],
            x.[Item No_],
            x.[Frequency (No_ of Days)],
            case when ext.fn_subscription_date_move(6,x.[Next Delivery Date]) < @date_close then @date_close else ext.fn_subscription_date_move(6,x.[Next Delivery Date]) end ndd,
            case when ext.fn_subscription_date_move(6,x.[Next Delivery Date]) < @date_close then 1 else 0 end is_overdue,
            x.[Quantity] * isnull(bc.[Quantity per],1) [Quantity],
            x.[Status]
        from
            [dbo].[IE$Subscriptions Line] x
        left join
            [dbo].[IE$BOM Component] bc
        on
            (
                x.[Item No_] = bc.[Parent Item No_]
            )
        outer apply
            (
                select top 1
                    sale_last
                from
                    @oos_plr
                where
                    (
                        location_id = (select top 1 location_id_dist from @l where company_id = 6 and subscription_loc = 1)
                    )
                order by
                    sale_last desc
            ) sale_last0
        outer apply
            (
                select top 1
                    nx.sale_last
                from
                    stock.oos_plr nx
                where
                    (
                        nx.item_id = @item_id
                    and nx.is_batch = 1
                    and nx.is_po = 0
                    and nx.is_to = 0
                    and nx.is_oos = 0
                    and nx.is_qa = 0
                    and nx.is_stop = 0
                    and nx.location_id = (select top 1 location_id_dist from @l where company_id = 6 and subscription_loc = 1)
                    )
                order by
                    row_version desc,
                    sale_last desc
            ) sale_last1
        where
            (
                ext.fn_subscription_date_move(6,x.[Next Delivery Date]) >= dateadd(month,-1,isnull(sale_last0.sale_last,sale_last1.sale_last))
            and x.[Status] in (0,6)
            and x.[Frequency (No_ of Days)] > 0
            and isnull(bc.[No_],x.[Item No_]) = @sku
            )
    ) l
cross apply
    (
        select
            iteration
        from
            db_sys.iteration i
        where
            ceiling(db_sys.fn_divide(datediff(day,l.ndd,@end_date_subs),l.[Frequency (No_ of Days)],0)) > i.iteration
    ) ndd
cross apply
    (
        select
            iteration
        from
            db_sys.iteration i
        where
            l.Quantity > i.iteration
    ) qty
outer apply
    (
        select
            1 is_priority,
            1 is_rf
        from    
            (
                select 
                    1 company_id,
                    rf.[Subscription No_],
                    rf.[Item No_],
                    rf.Quantity * isnull(bc.[Quantity per],1) Quantity,
                    row_number() over (partition by rf.[Subscription No_], rf.[Item No_] order by rf.[Expected Delivery Date])-1 iteration 
                from 
                    dbo.[UK$Ring Fencing Entry] rf
                left join
                    [dbo].[UK$BOM Component] bc
                on
                    (
                        rf.[Item No_] = bc.[Parent Item No_]
                    )
                where
                    (
                        rf.[Quantity] > 0
                    )

                union all

                select 
                    6 company_id,
                    rf.[Subscription No_], 
                    rf.[Item No_],
                    rf.Quantity * isnull(bc.[Quantity per],1) Quantity,
                    row_number() over (partition by rf.[Subscription No_], rf.[Item No_] order by rf.[Expected Delivery Date])-1 iteration 
                from 
                    dbo.[IE$Ring Fencing Entry] rf
                                left join
                    [dbo].[IE$BOM Component] bc
                on
                    (
                        rf.[Item No_] = bc.[Parent Item No_]
                    )
                where
                    (
                        rf.[Quantity] > 0
                    )
            ) rf
        where
            (
                l.company_id = rf.company_id
            and l.[Subscription No_] = rf.[Subscription No_]
            and l.[Item No_] = rf.[Item No_]
            and ndd.iteration = rf.iteration
            and rf.Quantity > qty.iteration
            )  
    ) rf

insert into @queue (location_id, ndd, is_oo)
select
    loc.location_id_dist location_id,
    @date_close ndd,
    1 is_oo
from 
    hs_consolidated.[Sales Line] sl
join 
    hs_consolidated.[Sales Header] sh 
on 
    (
        sh.company_id = sl.company_id
    and sh.No_ = sl.[Document No_] 
    and sl.[Document Type] = sh.[Document Type]
    )
join
    ext.Location el
on
    (
        sl.company_id = el.company_id
    and sl.[Location Code] = el.location_code
    )
cross apply
    (
        select top 1
            location_id_dist
        from
            @l l
        where
            (
                el.ID = l.location_id
            )
    ) loc
cross apply
    (
        select
            iteration
        from
            db_sys.iteration i
        where
            sl.[Outstanding Quantity] > i.iteration
    ) qty
where 
    (
        sl.[Outstanding Quantity] > 0
    and sh.[Sales Order Status] = 1
    and sl.[No_] = @sku
    )

update x set x.portion = x.calc from (select portion, db_sys.fn_divide(row_number() over (order by is_oo desc, ndd),sum(1) over (),default) calc from @queue where ndd < @end_date_subs) x

declare @l_tmp table (location_id int)

declare @op_tmp table (id int, is_po bit, is_to bit, ref int, avail_balance int, erd date, ldd date, portion float default 1, forecast_close_bal int, estimate_close_bal int)

declare @is_po bit, @is_to bit, @portion float

insert into @l_tmp
select distinct
    l.location_id_dist
from
    @queue q
join
    @l l
on
    (
        q.location_id = l.location_id
    )

while (select isnull(sum(1),0) from @l_tmp) > 0

    begin --e6da

    select top 1 @location_id = location_id from @l_tmp

    insert into @op_tmp (id, is_po, is_to, ref, avail_balance, erd, ldd)
    select
        id, is_po, is_to, ref, avail_balance, erd, ldd
    from
        @oos_plr
    where
        (
            location_id = @location_id
        and avail_balance > 0
        and ldd >= @date_close
        )

    update x set x.portion = x.calc from (select portion, db_sys.fn_divide(sum(avail_balance) over (order by id rows between unbounded preceding and current row),sum(avail_balance) over (),default) calc from @op_tmp where is_po = 0 and is_to = 0) x

    while (select isnull(sum(1),0) from @op_tmp) > 0

        begin --4e87

        select top 1 @id = id, @is_po = is_po, @is_to = is_to, @ref = ref, @avail_balance = avail_balance, @ldd = ldd, @erd = erd, @portion = portion from @op_tmp order by id

        update
            x
        set
            x.is_po = @is_po,
            x.is_to = @is_to,
            x.ref = @ref,
            x.erd = @erd,
            x.ldd = @ldd
        from
            (
                select
                    is_po,
                    is_to,
                    ref,
                    is_priority,
                    is_oo,
                    ndd,
                    erd,
                    ldd,
                    @avail_balance -  sum(1) over (order by is_priority desc, is_oo desc, ndd rows between unbounded preceding and current row) run_bal
                from
                    @queue q
                where
                    (
                        location_id = @location_id
                    -- and ndd < @ldd
                    -- and ndd < @end_date_subs
                    and ndd < isnull((select top 1 erd from @op_tmp where id > @id and is_po = 1 and location_id = @location_id order by id),@end_date_subs)
                    and portion <= @portion
                    and
                        (
                            (
                                @is_po = 0
                            and @is_to = 0
                            and ndd < @ldd
                            )
                        or
                            (
                                (
                                    @is_po = 1
                                or  @is_to = 1
                                )
                            -- and ndd < isnull((select top 1 erd from @op_tmp where id > @id order by id),@end_date_subs)
                            )
                        )
                    and ref is null
                    )
            ) x
        where
            (
                x.run_bal >= 0
            )

        delete from @op_tmp where id = @id

        end --4e87

    delete from @l_tmp where location_id = @location_id

    end --e6da

    update
        op
    set
        op.subs_total += sl.subs,
        op.avail_balance += sl.subs + sl.oo - sl.sub_out_6m_scope - sl.sub_b4_erd,
        op.ring_fenced += sl.rf,
        op.not_rf_subs_reserve += sl.subs - sl.rf - sl.sub_out_6m_scope - sl.sub_b4_erd,
        op.on_order += sl.oo,
        op.subs_overdue += sl.subs_overdue,
        op.rf_runout = sl.rf_runout,
        op.rf_item_card = (select top 1 rf_item_card from @rf_item_card ric where ric.location_id = op.location_id),
        op.sub_out_6m_scope = sl.sub_out_6m_scope,
        op.sub_b4_erd = sl.sub_b4_erd
    from
        @oos_plr op
    join
        (
            select
                location_id,
                is_po,
                is_to,
                ref,
                max(case when is_rf = 1 then ndd end) rf_runout,
                sum(case when is_rf = 1 then -1 else 0 end) rf,
                sum(case when is_oo = 0 then -1 else 0 end) subs,
                sum(case when is_oo = 1 then -1 else 0 end) oo,
                sum(case when is_overdue = 1 then -1 else 0 end) subs_overdue,
                sum(case when ndd >= isnull(po.erd,ndd) and ndd > @end_subs_res then -1 else 0 end) sub_out_6m_scope,
                sum(case when ndd > po.erd then -1 else 0 end) sub_b4_erd
            from
                @queue q
            outer apply
                (
                    select min(erd) erd from @oos_plr op where op.is_po = 1 and op.is_oos = 0 and op.location_id = q.location_id and q.is_po = 0
                ) po
            group by
                location_id,
                is_po,
                is_to,
                ref
        ) sl
    on
        (
            op.location_id = sl.location_id
        and op.is_po = sl.is_po
        and op.is_to = sl.is_to
        and op.ref = sl.ref
        )

set @estimate_open_date = @date_close

set @forecast_open_date = @date_close

while (select isnull(sum(1),0) from @oos_plr where avail_balance > 0 and is_end = 0) > 0

    begin --f3bd

        select top 1 
            @id = id,
            @location_id = location_id, 
            @ref = ref,
            @ldd = ldd,
            @erd = erd,
            @sale_first = sale_first,
            @sale_total = sale_total,
            @avail_balance = avail_balance,
            @reserved_stock = -(open_balance - avail_balance),
            @estimate_close_bal = avail_balance - sales_2day, --switched back to avail_balance, oos runs to when stock out of subs runs out --was available balance but because subs etc are applied earlier, in essence they'd be double counted 
            @estimate_daily_sales = estimate_daily_sales, 
            @estimate_cycle = estimate_cycle,
            @forecast_close_bal = avail_balance - sales_2day, --switched back to avail_balance, oos runs to when stock out of subs runs out --was available balance but because subs etc are applied earlier, in essence they'd be double counted 
            @forecast_cycle = forecast_cycle,
            @sub_out_6m_scope = sub_out_6m_scope,
            @sub_b4_erd = sub_b4_erd
        from 
            @oos_plr 
        where
            (
                avail_balance > 0
            and is_end = 0
            )
        order by 
            id
        
        if @location_id != @location_id_previous set @estimate_open_date = @date_close

        if @location_id != @location_id_previous set @forecast_open_date = @date_close

        if @erd is not null and @erd > @estimate_open_date set @estimate_open_date = @erd 

        if @erd is not null and @erd > @forecast_open_date set @forecast_open_date = @erd

        if @location_id != @location_id_previous set @estimate_batch_overflow = 0
        
        if @location_id != @location_id_previous set @forecast_batch_overflow = 0

        set @estimate_close_date = @estimate_open_date

        set @forecast_close_date = @forecast_open_date

        set @estimate_total_sales = 0

        set @forecast_total_sales = 0

        select
            @estimate_close_date = estimate_close_date,
            @estimate_close_bal = db_sys.fn_minus_min0(estimate_close_bal + @sub_out_6m_scope + @sub_b4_erd),
            @estimate_total_sales = estimate_total_sales + @reserved_stock + @sale_total,
            @estimate_batch_overflow = estimate_close_bal
        from
            (
                select top 1
                    estimate_close_date = dateadd(day,it.iteration,@estimate_close_date),
                    estimate_close_bal = @estimate_close_bal + (@estimate_daily_sales * it.iteration),
                    estimate_total_sales = @estimate_daily_sales * it.iteration
                from
                    db_sys.iteration it
                where
                    (
                        it.iteration > 0
                    and 
                        (
                            @estimate_close_bal + (@estimate_daily_sales * it.iteration) < 0
                        or  dateadd(day,it.iteration,@estimate_close_date) > @ldd
                        )
                    )
                order by
                    it.iteration
            ) estimate

        select top 1
            @forecast_close_date = forecast_close_date,
            @forecast_close_bal = db_sys.fn_minus_min0(forecast_close_bal + @sub_out_6m_scope + @sub_b4_erd),
            @forecast_total_sales = forecast_total_sales,
            @forecast_batch_overflow = forecast_close_bal,
            @is_eof = is_eof
        from
            (
                select 
                    forecast_close_date = fc._date,
                    forecast_close_bal = @forecast_close_bal - sum(isnull(fc.quantity,0)) over (order by fc._date rows between unbounded preceding and current row),
                    forecast_total_sales = -sum(isnull(fc.quantity,0)) over (order by fc._date rows between unbounded preceding and current row) + @reserved_stock + @sale_total,
                    is_eof = fc.is_eof
                from
                    (select _date, location_id, quantity, case when _date = max(_date) over () then 1 else 0 end is_eof from stock.forecast_current where _date >= @forecast_close_date and location_id = @location_id and item_id = @item_id) fc
            ) f
        where
            (
                f.forecast_close_bal < 0
            or  f.forecast_close_date > @ldd
            or  f.is_eof = 1
            )
        order by
            f.forecast_close_date

        update 
            @oos_plr 
        set 
            estimate_open_date = (select min(x._date) from (values (@estimate_open_date),(@sale_first)) x (_date)),
            estimate_close_date = @estimate_close_date,
            estimate_close_bal = db_sys.fn_round_by_sample(@avail_balance,@estimate_close_bal),
            estimate_cycle = datediff(day,(select min(x._date) from (values (@estimate_open_date),(@sale_first)) x (_date)),@estimate_close_date)-1,
            estimate_total_sales = -abs(@estimate_total_sales),
            forecast_open_date = (select min(x._date) from (values (@forecast_open_date),(@sale_first)) x (_date)),
            forecast_close_date = @forecast_close_date,
            forecast_close_bal = db_sys.fn_round_by_sample(@avail_balance,@forecast_close_bal),
            forecast_cycle = datediff(day,(select min(x._date) from (values (@forecast_open_date),(@sale_first)) x (_date)),@forecast_close_date)-1,
            forecast_daily_sales = -abs(db_sys.fn_divide(@forecast_total_sales,datediff(day,(select min(x._date) from (values (@forecast_open_date),(@sale_first)) x (_date)),@forecast_close_date)-1,0)),
            forecast_total_sales = @forecast_total_sales,
            is_end = 1,
            is_eof = @is_eof
        where
            (
                id = @id
            )

        set @estimate_open_date = @estimate_close_date

        set @forecast_open_date = @forecast_close_date

        set @location_id_previous = @location_id

    end --f3bd

update
    @oos_plr
set
    is_actual = 1,
    estimate_daily_sales = db_sys.fn_divide(sale_total,datediff(day,sale_first,sale_last),0),
    estimate_total_sales = sale_total,
    estimate_close_bal = avail_balance,
    estimate_open_date = sale_first,
    estimate_close_date = sale_last,
    forecast_daily_sales = db_sys.fn_divide(sale_total,datediff(day,sale_first,sale_last),0),
    forecast_total_sales = sale_total,
    forecast_close_bal = avail_balance,
    forecast_open_date = sale_first,
    forecast_close_date = sale_last,
    avail_balance = case when ldd < @date_close then 0 else avail_balance end
where 
    (
        avail_balance = 0
    or  ldd < @date_close
    )

--actual oos
insert into @oos_plr (id, location_id, is_batch, is_actual, is_oos, ref, estimate_cycle, estimate_total_sales, estimate_daily_sales, estimate_open_date, estimate_close_date, forecast_cycle, forecast_total_sales, forecast_daily_sales, forecast_open_date, forecast_close_date, is_end)
select
    op.id + 1,
    oos.location_id,
    1 is_batch,
    1 is_actual,
    1 is_oos,
    op.ref,
    datediff(day,oos.oos_from,oos.oos_to) estimate_cycle,
    op.estimate_daily_sales*datediff(day,oos.oos_from,oos.oos_to) estimate_total_sales,
    op.estimate_daily_sales,
    oos.oos_from,
    oos.oos_to,
    datediff(day,oos.oos_from,oos.oos_to) forecast_cycle,
    isnull(f.forecast_total_sales,0) forecast_total_sales,
    isnull(f.forecast_daily_sales,0) forecast_daily_sales,
    oos.oos_from forecast_open_date,
    oos.oos_to forecast_close_date, 
    1 is_end
from
    (
        select
            sale_gaps.location_id,
            sale_gaps.sale_day oos_from,
            dateadd(day,sale_gaps.gap-1,sale_day) oos_to
        from
            (
                select
                    location_id,
                    sale_day,
                    datediff(day,sale_day,lead(sale_day) over (partition by location_id order by sale_day)) gap
                from
                    (
                        select distinct
                            location_id, dateadd(day,iterate.iteration,op.sale_first) sale_day
                        from
                            (

                                select
                                    op.location_id,
                                    op.sale_first,
                                    op.sale_last
                                from
                                    @oos_plr op
                                where
                                    (
                                        op.is_batch = 1
                                    and op.is_oos = 0
                                    )

                                union all

                                select distinct
                                    base.location_id,
                                    isnull(expected_stock.erd,future_stock_check.edo),
                                    isnull(expected_stock.erd,future_stock_check.edo)
                                from
                                    (select location_id from @oos_plr where is_batch = 1 and is_qa = 0 and is_stop = 0 group by location_id having sum(avail_balance) = 0) base
                                left join
                                    (
                                        select
                                            location_id,
                                            min(erd) erd
                                        from
                                            @oos_plr
                                        where
                                            (
                                                is_po = 1
                                            or  is_to = 1
                                            or  is_qa = 1
                                            or  is_stop = 1
                                            )
                                        group by
                                            location_id
                                    ) expected_stock
                                  on
                                    (
                                        base.location_id = expected_stock.location_id
                                    )
                                outer apply
                                    (
                                        select
                                            location_id,
                                            @end_date_oos edo
                                        from
                                            @oos_plr w
                                        where
                                            (
                                                w.location_id = base.location_id
                                            )
                                        group by
                                            location_id
                                        having
                                            sum(avail_balance) = 0
                                    ) future_stock_check

                            ) op
                        cross apply
                            (
                                select
                                    iteration
                                from
                                    db_sys.iteration ix
                                where
                                    (
                                        ix.iteration <= datediff(day,op.sale_first,sale_last)+1
                                    )
                            ) iterate
                    ) sale_movement
            ) sale_gaps
        where
            (
                sale_gaps.gap > 6
            )
    ) oos
cross apply
    (
        select top 1
            id,
            ref,
            location_id,
            forecast_open_date,
            forecast_close_date,
            avail_balance,
            estimate_daily_sales
        from
            @oos_plr v
        where
            (
                oos.location_id = v.location_id
            and oos.oos_from > v.sale_last
            and v.is_batch = 1
            )
        order by
            v.sale_last desc
    ) op
outer apply
    stock.fn_forecast_sales (@item_id, oos.location_id, oos.oos_from, isnull(oos.oos_to,@end_date_oos)) f
where
    (
        op.avail_balance = 0
    )

--forecast oos
insert into @oos_plr (id, location_id, is_batch, is_po, is_to, is_actual, is_oos, ref, estimate_cycle, estimate_daily_sales, estimate_open_date, estimate_close_date, forecast_cycle, forecast_daily_sales, forecast_open_date, forecast_close_date)
select
    t.id+1,
    t.location_id,
    t.is_batch,
    t.is_po,
    t.is_to,
    t.is_actual,
    1 is_oos,
    t.ref,
    t.estimate_cycle,
    t.estimate_daily_sales,
    dateadd(day,1,t.estimate_open_date) estimate_open_date,
    dateadd(day,-1,isnull(n.next_erd,n.next_eod)) estimate_close_date,
    t.forecast_cycle,
    t.forecast_daily_sales,
    dateadd(day,1,t.forecast_open_date),
    dateadd(day,-1,isnull(n.next_erd,n.next_fod)) forecast_close_date
from
    (
        select
            id,
            max(id) over (partition by location_id) id_last,
            location_id,
            is_actual,
            is_batch,
            is_po,
            is_to,
            ref,
            subs_total,
            sale_first,
            sale_last,
            is_oos,
            db_sys.fn_minus_min0
                (
                    datediff
                        (
                            day,estimate_close_date,isnull(lead(estimate_open_date) over (partition by location_id order by id),@end_date_oos)
                        )
                )-1 estimate_cycle,
            estimate_daily_sales,
            estimate_close_date estimate_open_date,
            db_sys.fn_minus_min0
                (
                    datediff
                        (
                            day,forecast_close_date,isnull(lead(forecast_open_date) over (partition by location_id order by id),@end_date_oos)
                        )
                )-1 forecast_cycle,
            forecast_daily_sales,
            forecast_close_date forecast_open_date
        from 
            @oos_plr
        where
            (
                is_actual = 0
            )
    ) t
outer apply
    (
        select top 1
            k.estimate_open_date next_eod,
            k.forecast_open_date next_fod,
            k.erd next_erd
        from
            @oos_plr k
        where
            (
                t.location_id = k.location_id
            and t.id < k.id
            )
        order by
            k.estimate_open_date,
            k.forecast_open_date,
            k.erd
    ) n
where
    (
        (
            t.estimate_open_date <= coalesce(n.next_eod,n.next_erd,@end_date_oos)
        or  t.forecast_open_date <= coalesce(n.next_fod,n.next_erd,@end_date_oos)
        )
    and
        (
            datediff(day,t.estimate_open_date,coalesce(n.next_eod,n.next_erd,@end_date_oos)) > 5
        or  datediff(day,t.forecast_open_date,coalesce(n.next_fod,n.next_erd,@end_date_oos)) > 5
        )
    )
order by 
    id

update
    @oos_plr
set
    estimate_close_date = estimate_open_date
where
    (
        estimate_close_date < estimate_open_date
    )

update
    @oos_plr
set
    forecast_close_date = forecast_open_date
where
    (
        forecast_close_date < forecast_open_date
    )

update
    op
set
    op.estimated_lost_subs = s.qty
from
    @oos_plr op
cross apply
    (
        select
            sum(-1) qty
        from
            @queue q
        where
            (
                op.location_id = q.location_id
            and q.ndd < @end_subs_res
            and q.ndd >= op.estimate_open_date
            and q.ndd <= op.estimate_close_date
            and op.is_oos = 1
            and q.is_oo = 0
            )
    ) s

while (select isnull(sum(1),0) from @oos_plr where is_oos = 1 and is_end = 0) > 0

begin --70c3

    select top 1
        @id = id,
        @location_id = location_id,
        @estimate_daily_sales = estimate_daily_sales,
        @estimate_cycle = estimate_cycle,
        @estimate_open_date = estimate_open_date,
        @forecast_cycle = forecast_cycle,
        @forecast_open_date = forecast_open_date
    from
        @oos_plr t
    where
        (
            t.is_oos = 1
        and t.is_end = 0
        )
    order by
        id

    set @forecast_total_sales = 0

    select
        @forecast_total_sales = -sum(isnull(fc.quantity,0) + isnull(q.quantity,0))
    from
        (select _date, location_id, quantity from stock.forecast_current where _date >= @forecast_open_date and _date <= dateadd(day,@forecast_cycle-1,@forecast_open_date) and location_id = @location_id and item_id = @item_id) fc
    full join
        (select location_id, ndd, sum(1) quantity from @queue where ndd < @end_subs_res and ndd >= @forecast_open_date and ndd <= dateadd(day,@forecast_cycle-1,@forecast_open_date) and location_id = @location_id group by location_id, ndd) q
    on
        (
            fc.location_id = q.location_id
        and fc._date = q.ndd
        )
        
    update
        @oos_plr
    set
        is_end = 1,
        estimate_total_sales = db_sys.fn_round_by_sample(ring_fenced,(@estimate_daily_sales*@estimate_cycle)),
        forecast_daily_sales = db_sys.fn_divide(@forecast_total_sales,forecast_cycle,0),
        forecast_total_sales = db_sys.fn_round_by_sample(ring_fenced,@forecast_total_sales)
    where
        id = @id

end --70c3

update 
    op
set
    op.rf_deadline = dateadd(day,3,db_sys.foweek(dateadd(day,-ceiling(db_sys.fn_divide(not_rf_subs_reserve,forecast_daily_sales,0)),forecast_close_date),-4))
from
    @oos_plr op
join
    (
        select
            location_id,
            is_batch,
            ref
        from
            @oos_plr
        where
            (
                is_oos = 1
            )
    ) is_oos
on
    (
        op.location_id = is_oos.location_id
    and op.is_batch = is_oos.is_batch
    and op.ref = is_oos.ref
    )
where
    (
        op.is_batch = 1
    and op.not_rf_subs_reserve < 0
    and op.forecast_daily_sales < 0
    )

update @oos_plr set rf_deadline = @date_close where rf_deadline <= @date_close

update @oos_plr set ldd = null where ldd = datefromparts(2099,12,31)

update
    q
set
    q.is_bis = 1
from
    @queue q
cross apply
    (
        select top 1
            op.is_oos
        from
            @oos_plr op
        where
            (
                q.location_id = op.location_id
            and op.is_oos = 1
            and q.ndd >= op.forecast_open_date
            and q.ndd <= op.forecast_close_date
            )
    ) is_oos
where
    (
        (
            q.is_po = 1
        or  q.is_to = 1
        )
    and q.ndd < erd
    )

update 
    _iterations
set
    _iterations.ndd = dateadd(day,datediff(day,_base.ndd,_base.erd),_iterations.ndd)
from
    @queue _base
join
    @queue _iterations
on
    (
        _base.id = _iterations.id
    and _base.ndd < _iterations.ndd
    )
where
    (
        _base.is_bis = 1
    )

update
    @queue
set
    ndd = erd
where
    is_bis = 1

insert into @l_tmp
select distinct
    l.location_id_dist
from
    @queue q
join
    @l l
on
    (
        q.location_id = l.location_id
    )

while (select isnull(sum(1),0) from @l_tmp) > 0

    begin --52e7

    select top 1 @location_id = location_id from @l_tmp

    insert into @op_tmp (id, is_po, is_to, ref, erd, ldd, forecast_close_bal)
    select
        id, is_po, is_to, ref, erd, ldd, forecast_close_bal
    from
        @oos_plr
    where
        (
            location_id = @location_id
        and forecast_close_bal > 0
        and ldd >= @date_close
        )

    update x set x.portion = x.calc from (select portion, db_sys.fn_divide(sum(avail_balance) over (order by id rows between unbounded preceding and current row),sum(avail_balance) over (),default) calc from @op_tmp where is_po = 0 and is_to = 0) x

    while (select isnull(sum(1),0) from @op_tmp) > 0

        begin --490d

        select top 1 @id = id, @is_po = is_po, @is_to = is_to, @ref = ref, @forecast_close_bal = forecast_close_bal, @ldd = ldd, @erd = erd, @portion = portion from @op_tmp order by id

        update
            x
        set
            x.is_po2 = @is_po,
            x.is_to2 = @is_to,
            x.ref2 = @ref,
            x.erd2 = @erd,
            x.ldd2 = @ldd
        from
            (
                select
                    is_po2,
                    is_to2,
                    ref2,
                    is_priority,
                    is_oo,
                    ndd,
                    erd2,
                    ldd2,
                    @forecast_close_bal -  sum(1) over (order by is_priority desc, is_oo desc, ndd rows between unbounded preceding and current row) run_bal
                from
                    @queue q
                where
                    (
                        location_id = @location_id
                    and ndd < @ldd
                    and ndd > @end_subs_res
                    and
                        (
                            (
                                @is_po = 0
                            and @is_to = 0
                            and ndd < @ldd
                            )
                        or
                            (
                                (
                                    @is_po = 1
                                or  @is_to = 1
                                )
                            and ndd < isnull((select top 1 erd from @op_tmp where id > @id order by id),@end_date_subs)
                            )
                        )
                    and ref2 is null
                    )
            ) x
        where
            (
                x.run_bal >= 0
            )

        delete from @op_tmp where id = @id

        end --490d

    delete from @l_tmp where location_id = @location_id

    end --52e7

    update
        op
    set
        op.forecast_close_bal2 = op.forecast_close_bal + sl.subs,
        op.forecast_total_sales2 = op.forecast_total_sales + sl.subs,
        op.forecast_daily_sales2 = db_sys.fn_divide(op.forecast_total_sales + sl.subs,datediff(day,sl.ndd_min,sl.ndd_max),null)
    from
        @oos_plr op
    join
        (
            select
                location_id,
                is_po2,
                is_to2,
                ref2,
                min(ndd) ndd_min,
                max(ndd) ndd_max,
                sum(case when is_oo = 0 then -1 else 0 end) subs
            from
                @queue
            group by
                location_id,
                is_po2,
                is_to2,
                ref2
        ) sl
    on
        (
            op.location_id = sl.location_id
        and op.is_po = sl.is_po2
        and op.is_to = sl.is_to2
        and op.ref = sl.ref2
        )
    where
        (
            op.is_oos = 0
        )

insert into @l_tmp
select distinct
    l.location_id_dist
from
    @queue q
join
    @l l
on
    (
        q.location_id = l.location_id
    )

while (select isnull(sum(1),0) from @l_tmp) > 0

    begin --4dc5

    select top 1 @location_id = location_id from @l_tmp

    insert into @op_tmp (id, is_po, is_to, ref, erd, ldd, estimate_close_bal)
    select
        id, is_po, is_to, ref, erd, ldd, estimate_close_bal
    from
        @oos_plr
    where
        (
            location_id = @location_id
        and estimate_close_bal > 0
        and ldd >= @date_close
        )

    update x set x.portion = x.calc from (select portion, db_sys.fn_divide(sum(avail_balance) over (order by id rows between unbounded preceding and current row),sum(avail_balance) over (),default) calc from @op_tmp where is_po = 0 and is_to = 0) x

    while (select isnull(sum(1),0) from @op_tmp) > 0

        begin --e504

        select top 1 @id = id, @is_po = is_po, @is_to = is_to, @ref = ref, @estimate_close_bal = estimate_close_bal, @ldd = ldd, @erd = erd, @portion = portion from @op_tmp order by id

        update
            x
        set
            x.is_po3 = @is_po,
            x.is_to3 = @is_to,
            x.ref3 = @ref,
            x.erd3 = @erd,
            x.ldd3 = @ldd
        from
            (
                select
                    is_po3,
                    is_to3,
                    ref3,
                    is_priority,
                    is_oo,
                    ndd,
                    erd3,
                    ldd3,
                    @estimate_close_bal -  sum(1) over (order by is_priority desc, is_oo desc, ndd rows between unbounded preceding and current row) run_bal
                from
                    @queue q
                where
                    (
                        location_id = @location_id
                    and ndd < @ldd
                    and ndd > @end_subs_res
                    and
                        (
                            (
                                @is_po = 0
                            and @is_to = 0
                            and ndd < @ldd
                            )
                        or
                            (
                                (
                                    @is_po = 1
                                or  @is_to = 1
                                )
                            and ndd < isnull((select top 1 erd from @op_tmp where id > @id order by id),@end_date_subs)
                            )
                        )
                    and ref3 is null
                    )
            ) x
        where
            (
                x.run_bal >= 0
            )

        delete from @op_tmp where id = @id

        end --e504

    delete from @l_tmp where location_id = @location_id

    end --4dc5
--!!!
    update
        op
    set
        op.estimate_close_bal2 = op.estimate_close_bal + sl.subs,
        op.estimate_total_sales2 = op.estimate_total_sales + sl.subs,
        op.estimate_daily_sales2 = db_sys.fn_divide(op.estimate_total_sales + sl.subs,datediff(day,sl.ndd_min,sl.ndd_max),null)
    from
        @oos_plr op
    join
        (
            select
                location_id,
                is_po3,
                is_to3,
                ref3,
                min(ndd) ndd_min,
                max(ndd) ndd_max,
                sum(case when is_oo = 0 then -1 else 0 end) subs
            from
                @queue
            group by
                location_id,
                is_po3,
                is_to3,
                ref3
        ) sl
    on
        (
            op.location_id = sl.location_id
        and op.is_po = sl.is_po3
        and op.is_to = sl.is_to3
        and op.ref = sl.ref3
        )
    where
        (
            op.is_oos = 0
        )

if @test = 0

    begin --120d

        insert into stock.oos_plr
                (
                    row_version, /*pk_0*/ /*pk_1 rv_sub, defaults to 0*/
                    ref, /*pk_2*/
                    is_batch, /*pk_3*/
                    is_po, /*pk_4*/
                    is_po_1,
                    is_to, /*pk_5*/
                    is_oos, /*pk_6*/
                    is_qa,
                    is_stop,
                    is_actual,
                    entry_id,
                    item_id,
                    location_id, /*pk_7*/
                    ldd,
                    erd,
                    sale_first,
                    sale_last,
                    sale_total,
                    subs_total,
                    open_balance,
                    avail_balance,
                    ring_fenced,
                    not_rf_subs_reserve,
                    subs_overdue,
                    on_order,
                    estimated_lost_subs,
                    estimate_cycle,
                    estimate_daily_sales,
                    estimate_daily_sales2,
                    estimate_total_sales,
                    estimate_total_sales2,
                    estimate_close_bal,
                    estimate_close_bal2,
                    estimate_open_date,
                    estimate_close_date,
                    forecast_cycle,
                    forecast_daily_sales,
                    forecast_daily_sales2,
                    forecast_total_sales,
                    forecast_total_sales2,
                    forecast_close_bal,
                    forecast_close_bal2,
                    forecast_open_date,
                    forecast_close_date,
                    rf_deadline,
                    rf_item_card,
                    rf_runout,
                    is_eof,
                    is_original,
                    sub_out_6m_scope,
                    sub_b4_erd
                )
        select
            @row_version, /*pk_0*/
            t.ref, /*pk_2*/
            t.is_batch, /*pk_3*/
            t.is_po, /*pk_4*/
            t.is_po_1,
            t.is_to, /*pk_5*/
            t.is_oos, /*pk_6*/
            t.is_qa,
            t.is_stop,
            t.is_actual,
            t.id,
            @item_id item_id,
            t.location_id, /*pk_7*/
            t.ldd,
            t.erd,
            t.sale_first,
            t.sale_last,
            t.sale_total,
            t.subs_total,
            t.open_balance,
            t.avail_balance,
            t.ring_fenced,
            t.not_rf_subs_reserve,
            t.subs_overdue,
            t.on_order,
            t.estimated_lost_subs,
            t.estimate_cycle,
            t.estimate_daily_sales,
            t.estimate_daily_sales2,
            t.estimate_total_sales,
            t.estimate_total_sales2,
            t.estimate_close_bal,
            t.estimate_close_bal2,
            t.estimate_open_date,
            t.estimate_close_date,
            t.forecast_cycle,
            t.forecast_daily_sales,
            t.forecast_daily_sales2,
            t.forecast_total_sales,
            t.forecast_total_sales2,
            t.forecast_close_bal,
            t.forecast_close_bal2,
            t.forecast_open_date,
            t.forecast_close_date,
            t.rf_deadline,
            t.rf_item_card,
            t.rf_runout,
            t.is_eof,
            @is_original,
            t.sub_out_6m_scope,
            t.sub_b4_erd
        from
            @oos_plr t

        update ext.Item set last_oos_plr = getutcdate() where ID = @item_id

        delete from stock.oos_plr_queue where item_id in (select ID from ext.Item where No_ = @sku)

        insert into stock.forecast_subscriptions (row_version, location_id, item_id, ndd, quantity, ringfenced, bis_qty, is_original)
        select
            @row_version,
            q.location_id,
            @item_id item_id,
            q.ndd,
            sum(1) quantity,
            sum(case when q.is_rf = 1 then 1 else 0 end) ringfenced,
            sum(case when q.is_bis = 1 then 1 else 0 end) bis_qty,
            @is_original
        from
            @queue q
        where
            (
                q.is_oo = 0
            and q.ndd <= @end_date_subs
            )
        group by
            location_id,
            ndd

        update stock.oos_plr_log set ts_end = getutcdate() where item_id = @item_id and row_version = @row_version and rv_sub = 0

    end --120d

if @test = 1

    begin --aefb

    select
        (select row_version from stock.forecast_subscriptions_version where is_current = 1) [@row_version], *
    from
        @oos_plr
    -- where
    --     open_balance > 0
    -- or  is_oos = 1
    order by
        id

    select
        q.location_id,
        q.ref,
        q.ref2,
        q.ref3,
        @item_id item_id,
        min(q.ndd) ndd_min,
        max(q.ndd) ndd_max,
        min(q.ldd) ldd_min,
        max(q.ldd) ldd_max,
        min(q.erd) erd_min,
        max(q.erd) erd_max,
        min(q.portion) portion_min,
        max(q.portion) portion_max,
        sum(1) quantity,
        sum(case when q.is_rf = 1 then 1 else 0 end) ringfenced,
        sum(case when q.is_bis = 1 then 1 else 0 end) bis_qty
    from
        @queue q
    where
        (
            q.is_oo = 0
        and q.ndd <= @end_date_subs
        )
    group by
        location_id,
        q.ref,
        q.ref2,
        q.ref3

    end --aefb
GO