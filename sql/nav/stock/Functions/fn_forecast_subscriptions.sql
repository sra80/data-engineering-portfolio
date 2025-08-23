create or alter function stock.fn_forecast_subscriptions
    (
        @year int,
        @month int,
        @sku nvarchar(20)
    )

returns int

as

begin

    declare @r int = 0, @r_end int, @date date = eomonth(dateadd(month,1,datefromparts(@year,@month,1))), @qty int

    declare @t table (frq int, ndd date, qty int, r int, r_end int)

    insert into @t (frq, ndd, qty, r, r_end)
    select
        l.[Frequency (No_ of Days)] frq, 
        ext.fn_subscription_date_move(l.company_id,l.[Next Delivery Date]) ndd,
        sum(convert(int,l.Quantity)) qty,
        @r,
        db_sys.fn_divide(datediff(day,ext.fn_subscription_date_move(l.company_id,l.[Next Delivery Date]),@date),l.[Frequency (No_ of Days)],0)
    from
        hs_consolidated.[Subscriptions Header] h
    join
        hs_consolidated.[Subscriptions Line] (nolock) l
    on
        (
            h.company_id = l.company_id
        and h.No_ = l.[Subscription No_]
        )
    join
        ext.Item i
    on
        (
            l.company_id = i.company_id
        and l.[Item No_] = i.No_
        )
    where
        (
            ext.fn_subscription_date_move(l.company_id,l.[Next Delivery Date]) >= dateadd(day,-365,getutcdate())
        and l.[Status] = 0
        and l.[Frequency (No_ of Days)] > 0
        and h.[Cancelled Date] = datefromparts(1753,1,1)
        and datediff(day,ext.fn_subscription_date_move(l.company_id,l.[Next Delivery Date]),@date) > 0
        and l.[Item No_] = @sku
        )
    group by
        i.ID,
        l.[Frequency (No_ of Days)],
        ext.fn_subscription_date_move(l.company_id,l.[Next Delivery Date])

    select @r_end = max(r_end) from @t

    while @r < @r_end

        begin

            set @r += 1

            insert into @t (frq, ndd, qty, r, r_end)
            select
                frq,
                dateadd(day,frq,ndd),
                qty,
                @r,
                r_end
            from
                @t
            where
                r = @r - 1
            and r <= r_end

        end

    select
        @qty = sum(qty)
    from
        @t
    where
        (
            datepart(year,ndd) = @year
        and datepart(month,ndd) = @month
        )

    return @qty

end
GO
