create or alter view [stock].[vw_oos_plr]

as

select
    convert(bit,1) is_forecast_based,
    isnull(lo._output,op.location_id) location_id,
    case when op.is_batch = 1 then op.ref else (select top 1 ID from ext.Item_Batch_Info ibi where ibi.item_ID = op.item_id and ibi.variant_code = 'dummy' and ibi.batch_no = 'Not Provided') end batch_id,
    convert(bit,case when forecast.quantity > 0 then op.is_oos else 0 end) is_oos,
    isnull(case when op.is_oos = 1 then stock_in.is_qa end,0) is_qa,
    convert(bit,case when isnull(op.forecast_close_bal2,op.forecast_close_bal) > 0 and op.is_eof = 0 and op.ldd is not null then 1 else 0 end) is_plr,
    case when op.is_oos = 1 then stock_in.Reference end stock_in_ref,
    case when op.is_oos = 1 then op.forecast_open_date end oos_from,
    case when op.is_oos = 1 then nullif(op.forecast_close_date,datefromparts(year(getutcdate())+1,12,30)) end oos_to,
    case when op.is_oos = 1 then stock_in.erd end erd,
    case when op.is_oos = 1 then case when actual.ring_fenced > 0 then null else actual.rf_deadline end end ring_fence_deadline,
    case when op.is_oos = 1 then rf.rf_item_card end ring_fence_itemcard,
    case when op.is_oos = 1 and datediff(day,rf.rf_item_card,isnull(actual.rf_runout,actual.sale_last)) < -2 then isnull(actual.rf_runout,actual.sale_last) end ring_fence_runout,
    case when op.is_oos = 1 then rf.ring_fenced end ring_fenced_ttl,
    case when op.is_oos = 1 then actual.ring_fenced end ring_fenced,
    case when op.is_oos = 1 then actual.not_rf_subs_reserve end not_rf_subs_reserve,
    actual.on_order,
    actual.open_balance,
    actual.avail_balance,
    case when op.is_eof = 0 and op.ldd is not null then isnull(op.forecast_close_bal2,op.forecast_close_bal) else 0 end close_bal,
    -op.forecast_total_sales lost_sales,
    convert(int,case when actual.ring_fenced > 0 and actual.not_rf_subs_reserve > 0 and rf.rf_item_card < stock_in.erd then 1 else 0 end) highlight_not_rf_subs_reserve,
    op.open_balance open_balance_batch,
    convert(date,op.addTS) addTS,
    isnull(op.forecast_daily_sales2,op.forecast_daily_sales) daily_sales
from
    stock.oos_plr op
join
    ext.Item e_i
on
    (
        op.item_id = e_i.ID
    )
join
    hs_consolidated.Item h_i
on
    (
        e_i.company_id = h_i.company_id
    and e_i.No_ = h_i.No_
    and h_i.[Replenishment System] < 3
    )
left join
    stock.location_overide lo
on
    (
        op.location_id = lo._input
    )
cross apply
    (
        select
            min(rf_deadline) rf_deadline,
            max(rf_runout) rf_runout,
            max(x.sale_last) sale_last,
            sum(-x.ring_fenced) ring_fenced,
            sum(-x.not_rf_subs_reserve) not_rf_subs_reserve,
            sum(-on_order) on_order,
            sum(open_balance) open_balance,
            sum(avail_balance) avail_balance
        from 
            stock.oos_plr x 
        where 
            (
                x.location_id = op.location_id 
            and x.item_id = op.item_id
            and x.row_version = op.row_version 
            and x.rv_sub = op.rv_sub 
            and x.is_batch = 1
            and x.is_po = 0
            and x.is_to = 0 
            and x.is_oos = 0
            and x.is_qa = 0
            and x.is_stop = 0
            )
    ) actual
outer apply
    (
        select
            sum(-tx.ring_fenced) ring_fenced,
            min(tx.rf_item_card) rf_item_card
        from
            stock.oos_plr tx
        where
            (
                tx.row_version = op.row_version
            and tx.rv_sub = op.rv_sub
            and tx.location_id = op.location_id
            and tx.item_id = op.item_id
            )
    ) rf
outer apply
    (
        select
            sum(quantity) quantity
        from
            stock.forecast_current fc
        where
            (
                op.location_id = fc.location_id
            and op.item_id = fc.item_id
            and fc._date >= db_sys.foweek(getutcdate(),0)
            )
    ) forecast
outer apply
    (
        select top 1
            coalesce(pl.[Document No_],tl.[Document No_],concat(case when jj.is_stop = 1 then 'Stopped: ' else 'QA: ' end,ibi.batch_no,char(10),'(',format(jj.open_balance,'###,###,##0'),' units)')) Reference,
            jj.erd,
            jj.is_qa,
            jj.is_stop
        from
            stock.oos_plr jj
        left join
            ext.Purchase_Line pl
        on
            (
                jj.is_po = 1
            and jj.ref = pl.ID
            )
        left join
            ext.Transfer_Line tl
        on
            (
                jj.is_to = 1
            and jj.is_po = 0
            and jj.ref = tl.ID
            )
        left join
            ext.Item_Batch_Info ibi
        on
            (
                (
                    jj.is_qa = 1
                or  jj.is_stop = 1
                )
            and jj.ref = ibi.ID
            )
        where
            (
                jj.location_id = op.location_id
            and jj.item_id = op.item_id
            and jj.row_version = op.row_version
            and jj.rv_sub = op.rv_sub
            and jj.entry_id > op.entry_id
            and
                (
                    (
                        jj.is_po = 1
                    and jj.is_po_1 = 1
                    )
                or  jj.is_to = 1
                or  jj.is_qa = 1
                or  jj.is_stop = 1
                )
            and jj.is_oos = 0
            )
        order by
            jj.erd
    ) stock_in
where
    (
        op.row_version = (select max(row_version) from stock.forecast_subscriptions_version where is_current = 1)
    and op.rv_sub = 0
    and op.is_batch = 1
    and
        (    
            (
                isnull(op.forecast_total_sales2,op.forecast_total_sales) < 0
            and 
                (
                    (
                        datediff(day,op.forecast_open_date,isnull(op.forecast_close_date,datefromparts(2099,12,31))) > 5
                    and op.is_oos = 1
                    )
                or  stock_in.is_qa = 1
                or  stock_in.is_stop = 1
                )
            and 
                (
                    op.forecast_close_date is null
                or  op.forecast_close_date > getutcdate()
                )
            )
        or
            (
                op.open_balance > 0
            )
        )
    )

union all

select
    convert(bit,0) is_forecast_based,
    isnull(lo._output,op.location_id) location_id,
    case when op.is_batch = 1 then op.ref else (select top 1 ID from ext.Item_Batch_Info ibi where ibi.item_ID = op.item_id and ibi.variant_code = 'dummy' and ibi.batch_no = 'Not Provided') end batch_id,
    convert(bit,case when forecast.quantity > 0 then op.is_oos else 0 end) is_oos,
    isnull(case when op.is_oos = 1 then stock_in.is_qa end,0) is_qa,
    convert(bit,case when isnull(op.estimate_close_bal2,op.estimate_close_bal) > 0 and op.ldd is not null then 1 else 0 end) is_plr,
    case when op.is_oos = 1 then stock_in.Reference end stock_in_ref,
    case when op.is_oos = 1 then op.estimate_open_date end oos_from,
    case when op.is_oos = 1 then nullif(op.estimate_close_date,datefromparts(year(getutcdate())+1,12,30)) end oos_to,
    case when op.is_oos = 1 then stock_in.erd end erd,
    case when op.is_oos = 1 then case when actual.ring_fenced > 0 then null else actual.rf_deadline end end ring_fence_deadline,
    case when op.is_oos = 1 then rf.rf_item_card end ring_fence_itemcard,
    case when op.is_oos = 1 and datediff(day,rf.rf_item_card,isnull(actual.rf_runout,actual.sale_last)) < -2 then isnull(actual.rf_runout,actual.sale_last) end ring_fence_runout,
    case when op.is_oos = 1 then rf.ring_fenced end ring_fenced_ttl,
    case when op.is_oos = 1 then actual.ring_fenced end ring_fenced,
    case when op.is_oos = 1 then actual.not_rf_subs_reserve end not_rf_subs_reserve,
    actual.on_order,
    actual.open_balance,
    actual.avail_balance,
    case when op.ldd is not null then isnull(op.estimate_close_bal2,op.estimate_close_bal) else 0 end close_bal,
    -op.estimate_total_sales lost_sales,
    convert(int,case when actual.ring_fenced > 0 and actual.not_rf_subs_reserve > 0 then 1 else 0 end) highlight_not_rf_subs_reserve,
    op.open_balance open_balance_batch,
    convert(date,op.addTS) addTS,
    isnull(op.estimate_daily_sales2,op.estimate_daily_sales) daily_sales
from
    stock.oos_plr op
join
    ext.Item e_i
on
    (
        op.item_id = e_i.ID
    )
join
    hs_consolidated.Item h_i
on
    (
        e_i.company_id = h_i.company_id
    and e_i.No_ = h_i.No_
    and h_i.[Replenishment System] < 3
    )
left join
    stock.location_overide lo
on
    (
        op.location_id = lo._input
    )
cross apply
    (
        select
            min(rf_deadline) rf_deadline,
            max(rf_runout) rf_runout,
            max(x.sale_last) sale_last,
            sum(-x.ring_fenced) ring_fenced,
            sum(-x.not_rf_subs_reserve) not_rf_subs_reserve,
            sum(-on_order) on_order,
            sum(open_balance) open_balance,
            sum(avail_balance) avail_balance
        from 
            stock.oos_plr x 
        where 
            (
                x.location_id = op.location_id 
            and x.item_id = op.item_id
            and x.row_version = op.row_version 
            and x.rv_sub = op.rv_sub 
            and x.is_batch = 1
            and x.is_po = 0
            and x.is_to = 0 
            and x.is_oos = 0
            and x.is_qa = 0
            and x.is_stop = 0
            )
    ) actual
outer apply
    (
        select
            sum(-tx.ring_fenced) ring_fenced,
            min(tx.rf_item_card) rf_item_card
        from
            stock.oos_plr tx
        where
            (
                tx.row_version = op.row_version
            and tx.rv_sub = op.rv_sub
            and tx.location_id = op.location_id
            and tx.item_id = op.item_id
            )
    ) rf
outer apply
    (
        select
            sum(-quantity) quantity
        from
            stock.forecast_current fc
        where
            (
                op.location_id = fc.location_id
            and op.item_id = fc.item_id
            and fc._date >= db_sys.foweek(getutcdate(),0)
            )
    ) forecast
outer apply
    (
        select top 1
            coalesce(pl.[Document No_],tl.[Document No_],concat(case when jj.is_stop = 1 then 'Stopped: ' else 'QA: ' end,ibi.batch_no,char(10),'(',format(jj.open_balance,'###,###,##0'),' units)')) Reference,
            jj.erd,
            jj.is_qa,
            jj.is_stop
        from
            stock.oos_plr jj
        left join
            ext.Purchase_Line pl
        on
            (
                jj.is_po = 1
            and jj.ref = pl.ID
            )
        left join
            ext.Transfer_Line tl
        on
            (
                jj.is_to = 1
            and jj.is_po = 0
            and jj.ref = tl.ID
            )
        left join
            ext.Item_Batch_Info ibi
        on
            (
                (
                    jj.is_qa = 1
                or  jj.is_stop = 1
                )
            and jj.ref = ibi.ID
            )
        where
            (
                jj.location_id = op.location_id
            and jj.item_id = op.item_id
            and jj.row_version = op.row_version
            and jj.rv_sub = op.rv_sub
            and jj.entry_id > op.entry_id
            and
                (
                    (
                        jj.is_po = 1
                    and jj.is_po_1 = 1
                    )
                or  jj.is_to = 1
                or  jj.is_qa = 1
                or  jj.is_stop = 1
                )
            and jj.is_oos = 0
            )
        order by
            jj.erd
    ) stock_in
where
    (
        op.row_version = (select max(row_version) from stock.forecast_subscriptions_version where is_current = 1)
    and op.rv_sub = 0
    and op.is_batch = 1
    and
        (    
            (
                isnull(op.estimate_total_sales2,op.estimate_total_sales) < 0
            and (
                    (
                        datediff(day,op.forecast_open_date,isnull(op.forecast_close_date,datefromparts(2099,12,31))) > 5
                    and op.is_oos = 1
                    )
                or  stock_in.is_qa = 1
                or  stock_in.is_stop = 1
                )
            and 
                (
                    op.estimate_close_date is null
                or  op.estimate_close_date > getutcdate()
                )
            )
        or
            (
                op.open_balance > 0
            )
        )
    )