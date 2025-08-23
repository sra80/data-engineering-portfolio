create or alter view marketing.ProductLifespan

as

with cal as
    (
        select
            dateadd(year,iteration,datefromparts(year(getutcdate())-ws.window_span,1,1)) date_open,
            dateadd(year,iteration,datefromparts(year(getutcdate())-ws.window_span,12,31)) date_close,
            datefromparts(year(getutcdate())-ws.window_span,1,1) window_start
        from
            db_sys.iteration
        cross apply
            (
                select
                    6 window_span
            ) ws
        where
            iteration <= ws.window_span
    )

, item as
    (
        select
            i.company_id,
            i.ID item_id,
            datefromparts(year(i.firstOrder),1,1) year_from,
            datefromparts(year(i.lastOrder),12,31) year_to,
            i.lastOrder,
            convert(bit,case when ii.[Status] = 2 then 1 else 0 end) is_discontinued
        from
            ext.Item i
        join
            hs_consolidated.Item ii
        on
            (
                i.company_id = ii.company_id
            and i.No_ = ii.No_
            )
    )

select
    u.date_open _date,
    u.company_id,
    u.item_id,
    u.[Item Status],
    case u.[Item Status]
        when 'Initial Product Count' then 0
        when 'New' then 1
    else
        2
    end item_status_sort,
    u._count
from
    (
        select
            cal.date_open,
            item.company_id,
            item.item_id,
            case when item.year_from < cal.window_start and cal.window_start = cal.date_open then 1 else 0 end [Initial Product Count],
            case when item.year_from = cal.date_open then 1 else 0 end [New],
            case when item.year_to = cal.date_close and (is_discontinued = 1 or datediff(month,item.lastOrder,getutcdate()) >= 12) then -1 else 0 end [Discontinued]
        from
            item
        cross apply
            cal
        where
            (
                item.year_from <= cal.date_open
            and item.year_to >= cal.date_close
            )
    ) t
unpivot
    (
        _count
    for
        [Item Status] in ([Initial Product Count], [New], [Discontinued])
    ) u
where
    (
        abs(u._count) > 0
    )