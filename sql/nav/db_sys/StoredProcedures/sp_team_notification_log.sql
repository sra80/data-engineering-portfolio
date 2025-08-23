create or alter procedure [db_sys].[sp_team_notification_log]

as

insert into db_sys.team_notification_auditLog (tnl_ID, tnc_ID)
select
    tnl.ID, tns.tnc_ID
from
    db_sys.team_notification_log tnl
join
    db_sys.team_notification_setup tns
on
    (
        tnl.ens_ID = tns.ens_ID
    )
join
    db_sys.team_notification_channels tnc
on
    (
        tnc.ID = tns.tnc_ID
    and tnc.deleteTS is null
    )
where
    (
        tnl.postTS is null
    and not exists (select 1 from db_sys.team_notification_auditLog x where x.tnl_ID = tnl.ID and x.tnc_ID = tns.tnc_ID)
    )
GO
