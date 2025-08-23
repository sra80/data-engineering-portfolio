create or alter procedure [ext].[sp_Prospect]

as

set nocount on

--load new prospects

declare @rowcount int = 1

while @rowcount > 0

begin

    insert into ext.Prospect (cus, email_valid, optcheck, email_optin, post_optin, phone_optin, email_ts, post_ts, phone_ts)
    select top 10000
        cus.No_, db_sys.fn_email_isValid(cus.[E-Mail]) email_valid, 1 optcheck, opt.email_optin, opt.post_optin, opt.phone_optin, opt.email_ts, opt.post_ts, opt.phone_ts
    from
        [dbo].[UK$Customer] cus
    cross apply
        ext.fn_Customer_Comms_OptInTS(cus.No_) opt
    where
        (
            cus.No_ not in (select cus from ext.Customer)
        and cus.No_ not in (select cus from ext.Prospect)
        )

set @rowcount = @@rowcount

end

--update existing prospects
update c set
    c.email_valid = db_sys.fn_email_isValid(cus.[E-Mail]), -- email validation added here
    c.email_optin = n.email_optin,
    c.post_optin = n.post_optin,
    c.phone_optin = n.phone_optin,
    c.email_ts = n.email_ts,
    c.post_ts = n.post_ts,
    c.phone_ts = n.phone_ts,
    c.optcheck = 1,
    c.UpdatedTSUTC = getutcdate(),
    c.update_Prospect_OptIn_History = 1 --
from
    ext.Prospect c
join
    [dbo].[UK$Customer] cus
on
    (
        c.cus = cus.No_
    )
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
                                            ext.Prospect c
                                    ) x
                    ) 
            
            union

            select
                cus
            from
                ext.Prospect
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

--remove converted prospects
delete from ext.Prospect where cus in (select cus from ext.Customer)

--add converted prospects to converted list 
insert into ext.Prospect_Convert (cus, _start_date, _end_date)
select 
    e.cus,
    d.[Created Date],
    dateadd(day,-1,e.first_order_date)
from
    dbo.[UK$Customer] d
join
    ext.Customer e
on
    (
        d.No_ = e.cus
    )
where
    cus not in (select cus from ext.Prospect_Convert)
and datediff(day,d.[Created Date],e.first_order_date) > 1

GO
