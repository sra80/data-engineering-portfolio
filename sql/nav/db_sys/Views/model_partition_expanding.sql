CREATE view db_sys.model_partition_expanding

as

/*
Partition   Range                       Schedule
0           Today                       Every 30 minutes
1           Current Month               Daily
2           Last Month                  Monthly
3           2 Months Ago                Monthly
4           3 Months Ago                Monthly
5           4 Months Ago                Monthly
6           5 Months Ago                Monthly
7           June Last Year to < P6      Monthly
8           Last Year First Half        Annually
9           Year Before Last Last Half  Annually
10          Year Before Last First Half Annually
*/

with p0 as
    (
             select 
            0 _partition,
            convert(date,dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate())) date_start,
            convert(date,dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate())) date_end
        from
            sys.time_zone_info tz
        where
            tz.[name] = 'GMT Standard Time'
    )

, p1 as
    (
        select 
            1 _partition,
            db_sys.fomonth(dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate())) date_start,
            convert(date,dateadd(day,-1,dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate()))) date_end
        from
            sys.time_zone_info tz
        where
            tz.[name] = 'GMT Standard Time'
    )

, p2_6 as
    (
        select 
            2 _partition,
            dateadd(month,-1,db_sys.fomonth(dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate()))) date_start,
            eomonth(dateadd(month,-1,dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate()))) date_end
        from
            sys.time_zone_info tz
        where
            tz.[name] = 'GMT Standard Time'

        union all

        select
            _partition+1,
            dateadd(month,-1,date_start),
            eomonth(dateadd(month,-1,date_start))
        from
            p2_6
        where
            _partition < 6
    )

, p7 as
    (
        select 
            7 _partition,
            datefromparts(year(date_start)-1,7,1) date_start,
            dateadd(day,-1,date_start) date_end
        from
            p2_6
        where
            _partition = 6
    )

,p9_10 as
    (
        select
            10 _partition,
            datefromparts(year(date_start)-2,1,1) date_start,
            datefromparts(year(date_start)-2,6,30) date_end
        from
            p2_6
        where
            _partition = 6

        union all

        select
            _partition-1 _partition,
            dateadd(month,6,date_start),
            eomonth(dateadd(month,6,date_end))
        from
            p9_10
        where
            _partition > 8
    )

select
    _partition,
    date_start,
    date_end
from
    p0

union all

select
    _partition,
    date_start,
    date_end
from
    p1

union all

select
    _partition,
    date_start,
    date_end
from
    p2_6

union all

select
    _partition,
    date_start,
    date_end
from
    p7

union all

select
    _partition,
    date_start,
    date_end
from
    p9_10
GO
