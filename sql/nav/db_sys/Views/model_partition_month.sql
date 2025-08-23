CREATE view db_sys.model_partition_month

as

with x (_partition, _year, _month) as
    (
        select 
             0,
             year(dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate()))-2,
             1
         from
             sys.time_zone_info tz
         where
             tz.[name] = 'GMT Standard Time'

        union all

        select
            _partition + 1,
            case when _month = 12 then _year + 1 else _year end,
            case when _month = 12 then 1 else _month + 1 end
        from
            x
        where
            _partition < 35
    )


select
    _partition,
    _year,
    _month
from 
    x
GO
