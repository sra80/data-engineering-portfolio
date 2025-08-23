create or alter procedure [ext].[sp_Customer]

as

set nocount on

declare @source table (cus nvarchar(20), order_date date, channel_code nvarchar(20), platformID int, ID int)

insert into @source (cus, order_date, channel_code, platformID, ID)
select
    sales.cus,
    source_info.order_date,
    source_info.channel_code,
    source_info.platformID,
    isnull((select ID from ext.Customer where cus = sales.cus),(select ID from ext.Prospect where cus = sales.cus)) ID
from
    (
        select
            [Sell-to Customer No_] cus
        from
            ext.[Sales_Header]
        where
            [Sales Order Status] = 1

        union

        select 
            [Sell-to Customer No_]
        from
            ext.[Sales_Header_Archive]
        where
            (
                [Sell-to Customer No_] not in (select cus from ext.Customer) --add 
            --or convert(date,[Order Date]) >= dateadd(day,-2,convert(date,isnull((select max(AddedTSUTC) from ext.Customer),getutcdate()))) --rem 
            )
    ) sales
cross apply
    ext.fn_Customer_Platform_FirstOrder(sales.cus) source_info

update @source set ID = next value for ext.sq_Customer where ID is null

merge ext.Customer t
using @source s
on
    (
        t.cus = s.cus
    )
when not matched by target then
    insert (cus, first_platformID, first_channel_code, first_order_date, ID)
    values (s.cus, s.platformID, s.channel_code, s.order_date, s.ID)
when matched and (t.first_platformID != s.platformID or t.first_channel_code != s.channel_code or t.first_order_date != s.order_date) then update set
    t.first_platformID = s.platformID,
    t.first_channel_code = s.channel_code,
    t.first_order_date = s.order_date,
    t.UpdatedTSUTC = getutcdate();

--update opt in/out comm preferences added to procedure in 
update c set
    c.email_optin = n.email_optin,
    c.post_optin = n.post_optin,
    c.phone_optin = n.phone_optin,
    c.email_ts = n.email_ts,
    c.post_ts = n.post_ts,
    c.phone_ts = n.phone_ts,
    c.optcheck = 1
from
    ext.Customer c
join
    (
    select
        l.cus,
        p.email_optin,
        p.post_optin,
        p.phone_optin,
        p.email_ts,
        p.post_ts,
        p.phone_ts
    from
        (
            select
                [Customer No_] cus
            from 
                [UK$Customer Preferences Log]
            where
                [Modified DateTime] > 
                    (
                            select 
                                max(x.x) 
                            from 
                                (
                                        select 
                                            (
                                                    select 
                                                        max(ts) 
                                                            from 
                                                                (
                                                                        values(email_ts), (post_ts), (phone_ts)
                                                                ) as value(ts)
                                                ) x 
                                        from 
                                            ext.Customer c
                                    ) x
                    ) 
            
            union all

            select
                cus
            from
                ext.Customer
            where
                optcheck = 0
        ) l
    cross apply
        [ext].[fn_Customer_Comms_OptInTS](l.cus) p
    ) n
on
    (
        c.cus = n.cus
    )

--streak info
update
    cus
set
    cus.streak_first_order = streak.first_order,
    cus.streak_last_order = streak.last_order,
    cus.streak_last_update = getutcdate()
from
    ext.Customer cus
outer apply
    ext.fn_Customer_Active_Streak(cus.cus) streak
where
    (
        cus.streak_last_update is null
    or  datediff(hour,cus.streak_last_update,getutcdate()) > 24
    )