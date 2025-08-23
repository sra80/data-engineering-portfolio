create or alter function db_sys.fn_auditLog_info
    (
        @auditLog_ID int
    )

returns table

as

return
select
    s.ID logicApp_Identifier,
    a.session_event_count,
    case when a.session_event_count = 1 then convert(nvarchar,@auditLog_ID) else a.session_auditLog_IDs end session_auditLog_IDs,
    case when a.session_event_count = 1 then auditLog_ID.eventName else a.session_events end session_events,
    w.runtime,
    case when a.session_event_count = 1 then w.runtime else x.total_runtime end total_runtime,
    case when x.ttl_rt_sec-x.rt_act <= 0 or a.session_event_count = 1 then 'None' else db_sys.fn_datediff_string(dateadd(second,-(x.ttl_rt_sec-x.rt_act),getutcdate()),getutcdate(),default) end runtime_gap,
    case when a.session_event_count = 1 then '100%' else format(round(w.rt_sec/convert(float,x.ttl_rt_sec),4),'0.00%') end runtime_portion,
    case when x.ttl_rt_sec-x.rt_act < 0 or a.session_event_count = 1 then '0.00%' else format(round((x.ttl_rt_sec-x.rt_act)/convert(float,x.ttl_rt_sec),4),'0.00%') end runtime_gap_portion
from
    (select ID, eventName, place_holder_session from db_sys.auditLog where ID = @auditLog_ID) auditLog_ID
left join
    db_sys.auditLog_logicApp_identifier s
on
    (
        auditLog_ID.place_holder_session = s.sessionID
    )
left join
    (select g.ID, string_agg(f.ID,',') session_auditLog_IDs, string_agg(h.eventName,',') session_events, sum(1) session_event_count from db_sys.auditLog f right join  (select place_holder_session, ID from db_sys.auditLog union select null, @auditLog_ID) g on f.place_holder_session = g.place_holder_session left join db_sys.auditLog h on f.ID = h.ID  group by g.ID) a
on
    (
        auditLog_ID.ID = a.ID
    )
left join
    (select ID, db_sys.fn_datediff_string(eventUTCStart,isnull(eventUTCEnd,getutcdate()),default) runtime, datediff(second,eventUTCStart,isnull(eventUTCEnd,getutcdate())) rt_sec from db_sys.auditLog) w
on
    (
        auditLog_ID.ID = w.ID
    )
left join
    (select c.ID, db_sys.fn_datediff_string(min(a.eventUTCStart),case when sum(case when a.eventUTCEnd is null then 1 else 0 end) > 0 then getutcdate() else max(a.eventUTCEnd) end,default) total_runtime, datediff(second,min(a.eventUTCStart),case when sum(case when a.eventUTCEnd is null then 1 else 0 end) > 0 then getutcdate() else max(a.eventUTCEnd) end) ttl_rt_sec, sum(datediff(second,a.eventUTCStart,isnull(a.eventUTCEnd,getutcdate()))) rt_act, sum(case when a.eventUTCEnd is null then 1 else 0 end) x from db_sys.auditLog a join db_sys.auditLog b on a.ID = b.ID join db_sys.auditLog c on b.place_holder_session = c.place_holder_session group by c.ID) x
on
    (
        auditLog_ID.ID = x.ID
    )
GO
