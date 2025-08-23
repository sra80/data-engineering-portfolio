CREATE procedure ext.sp_Prospect_OptIn_History

as

set nocount on

while (select sum(1) from ext.Prospect where update_Prospect_OptIn_History = 1) > 0

begin

    insert into stg.Prospect_OptIn_History (cus, _start_date, _end_date, email_optin, opt_source)
    select 
        p.cus,
        o._start_date,
        o._end_date,
        o.opt_in_status,
        o.opt_source
    from
        (select top 10000 cus from ext.Prospect where update_Prospect_OptIn_History = 1) p
    cross apply
        ext.fn_Customer_opt_in_status(p.cus,default,default,default) o

    insert into marketing.csh_opt_source (opt_source, opt_source_clean)
    select distinct opt_source, opt_source from [stg].[Prospect_OptIn_History] where len(opt_source) > 0 and opt_source not in (select opt_source from marketing.csh_opt_source)

    merge ext.Prospect_OptIn_History t
    using stg.Prospect_OptIn_History s
    on
        (
            t.cus = s.cus
        and t._start_date = s._start_date
        )
    when matched and t.email_optin != s.email_optin then update set
        t.email_optin = s.email_optin, updatedTSUTC = getutcdate()
    when not matched by target then insert
        (cus, _start_date, _end_date, email_optin, opt_source_key)
    values
        (s.cus, s._start_date, s._end_date, s.email_optin, marketing.fn_csh_opt_source_lookup(s.opt_source));

    update ext.Prospect set update_Prospect_OptIn_History = 0 where cus in (select cus from stg.Prospect_OptIn_History)

    truncate table stg.Prospect_OptIn_History

end

while (select sum(1) from ext.Prospect_Convert where update_Prospect_OptIn_History = 1) > 0

begin

    insert into stg.Prospect_OptIn_History (cus, _start_date, _end_date, email_optin, opt_source)
    select
        p.cus,
        o._start_date,
        o._end_date,
        o.opt_in_status,
        o.opt_source
    from
        (select top 10000 cus, _start_date, _end_date from ext.Prospect_Convert where update_Prospect_OptIn_History = 1) p
    cross apply
        ext.fn_Customer_opt_in_status(p.cus,p._start_date,p._end_date,default) o

    insert into marketing.csh_opt_source (opt_source, opt_source_clean)
    select distinct opt_source, opt_source from [stg].[Prospect_OptIn_History] where len(opt_source) > 0 and opt_source not in (select opt_source from marketing.csh_opt_source)

    merge ext.Prospect_OptIn_History t
    using stg.Prospect_OptIn_History s
    on
        (
            t.cus = s.cus
        and t._start_date = s._start_date
        )
    when matched and t.email_optin != s.email_optin then update set
        t.email_optin = s.email_optin, updatedTSUTC = getutcdate()
    when not matched by target then insert
        (cus, _start_date, _end_date, email_optin, opt_source_key)
    values
        (s.cus, s._start_date, s._end_date, s.email_optin, marketing.fn_csh_opt_source_lookup(s.opt_source));

    update ext.Prospect_Convert set update_Prospect_OptIn_History = 0 where cus in (select cus from stg.Prospect_OptIn_History)

    truncate table stg.Prospect_OptIn_History

end
GO
