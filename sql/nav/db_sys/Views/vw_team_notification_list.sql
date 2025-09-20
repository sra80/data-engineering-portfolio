create or alter view [db_sys].[vw_team_notification_list]

as

select
    tnl.ID tnl_ID,
    tna.tnc_ID,
    tnc.channel_id,
    tnl.message_subject,
    case when tnl.teams_root_mid is null then tnl.message_body else case when ens.reply_to_previous > 0 or tns.is_reply_on_same = 1 then isnull(tnl.message_reply,tnl.message_body) else tnl.message_body end end message_body,
    tnl.teams_message_id,
    case when tnl.teams_root_mid is null then 0 else 1 end is_reply,
    concat('/Shared Documents/',tnc.channel_name) sharepoint_location,
    concat(lower(tnl.place_holder),'.html') file_name,
    concat('Please <a href="https://xxxxx.sharepoint.com/:u:/r/sites/BusinessIntelligenceAlerts/Shared%20Documents/',replace(tnc.channel_name,' ','%20'),'/',lower(tnl.place_holder),'.html?csf=1&web=1&e=2OnSjA">click here</a> to view the message.<p style="font-size:8px; ">',tnl.ID,'</p>') sharepoint_url,
    case when datalength(tnl.message_body) > 102400 then 1 else 0 end message_size_exceeded
from
    db_sys.team_notification_log tnl
join
    db_sys.team_notification_auditLog tna
on
    (
        tnl.ID = tna.tnl_ID
    )
join
    db_sys.team_notification_channels tnc
on
    (
        tna.tnc_ID = tnc.ID
    )
left join
    db_sys.team_notification_setup tns
on
    (
        tnl.ens_ID = tns.ens_ID
    and tna.tnc_ID = tns.tnc_ID
    )
left join
    db_sys.email_notifications_schedule ens
on
    (
        tnl.ens_ID = ens.ID
    )
where
    (
        tnl.postTS is null
    and tnc.deleteTS is null
    )

GO