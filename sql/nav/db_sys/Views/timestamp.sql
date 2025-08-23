
CREATE view [db_sys].[timestamp]

as

select 
     dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate()) ts
    ,tz.[name] timezone
    ,tz.current_utc_offset
    ,tz.is_currently_dst
    ,uc.username
from
    sys.time_zone_info tz
left join
    db_sys.user_config uc
on  
    (
        tz.[name] = uc.timezone collate database_default
    )
-- cross apply
-- 	db_sys.process_model_navAutoTask_status
GO
