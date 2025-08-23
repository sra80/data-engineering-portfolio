CREATE function marketing.fn_CSH_MovingWindow_EmailOptIn
    (
        @cus nvarchar(20), 
        @event_date date 
    )

returns table

as

return

with n as
    (
    select
        event_date,
        opt_status
    from
        (
        select
            convert(date,[Modified DateTime]) event_date,
            case when [Status] = 0 then 1 else 0 end opt_status,
            case when lag([Status]) over (order by [Modified DateTime]) = [Status] then 0 else 1 end opt_status_change
        from
            [UK$Customer Preferences Log] 
        where
            [Entry No_] in
                (
                select
                    max([Entry No_]) last_entry
                from
                    [UK$Customer Preferences Log] 
                where 
                    (
                        [Record Code] = 'EMAIL' 
                    and [Customer No_] = @cus
                    )
                group by
                    convert(date,[Modified DateTime])
                )
        ) x0
    where
        (
            opt_status_change = 1
        )
    )

select
    event_date,
    opt_status
from
    n
where
    event_date > @event_date
and event_date < (select top 1 [Start Date] from ext.Customer_Status_History where No_ = @cus and [Start Date] > @event_date order by [Start Date])

union all

-- select top 1
--     null,
--     opt_status
-- from
--     n
-- where
--     n.event_date <= @event_date

select 
    null,
    isnull(opt_status,0) opt_status
from
    (
        select @event_date event_date
    ) e
outer apply
    (
        select top 1 opt_status from n where event_date <= e.event_date
    ) n
GO
