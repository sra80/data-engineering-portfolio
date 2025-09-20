CREATE view [db_sys].[model_partition_bi]

-- with schemabinding

as
/*
_partition 0-5 last 6 months
_partition 6 gap between July 1st of last year and above
_partition 7-13 January 4 years ago to June 30 of last year

recommended schedule
_partition  schedule
0           everyday (current month)
1           everyday (last month)
2           everyday
3           every month
4           every month
5           every month
6           every month
7           every year
8           every year
9           every year
10          every year
11          every year
12          every year
13          every year
*/

with cal0 as
    (
        select 
            0 _partition,
            db_sys.fomonth(dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate())) date_start,
            eomonth(dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate())) date_end
        from
            sys.time_zone_info tz
        where
            tz.[name] = 'GMT Standard Time'

        union all

        select
            _partition + 1,
            dateadd(month,-1,date_start),
            eomonth(dateadd(month,-1,date_start))
        from
            cal0
        where
            _partition < 5

    )
, cal1 as
    (
        select
            13 _partition,
            datefromparts(year(getutcdate())-4,1,1) date_start,
            datefromparts(year(getutcdate())-4,6,30) date_end

        union all

        select
            _partition - 1,
            dateadd(month,6,date_start),
            eomonth(dateadd(month,6,date_end))
        from
            cal1 
        where
            _partition > 7
         
    )

select _partition, date_start, date_end from cal0
union all 
select 6, (select dateadd(day,1,date_end) from cal1 where _partition = 7), (select dateadd(day,-1,date_start) from cal0 where _partition = 5)
union all
select _partition, date_start, date_end from cal1
GO
