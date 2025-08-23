CREATE procedure finance.sp_SalesInvoices

as

set nocount on

declare @sql nvarchar(max), @auditLog_ID int, @step int

select top 1 @auditLog_ID = ID from db_sys.auditLog where replace(replace(eventName,'[',''),']','') = 'finance.sp_SalesInvoices' and try_convert(uniqueidentifier,eventDetail) is not null order by ID desc

if @auditLog_ID is null select @auditLog_ID = next value for finance.sq_sp_SalesInvoices

declare @t table (_sql nvarchar(max), step int identity(0,1))

;with cal (_synonym, _year, _month, _year_end, _today) as
    (
        select
            -12,
            year(dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate()))-3,
            1,
            year(dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate())),
            convert(date,dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate()))
        from
            sys.time_zone_info tz
        where
            tz.[name] = 'GMT Standard Time'

        union all

        select
            _synonym + 1,
            case when _month = 12 then _year + 1 else _year end,
            case when _month = 12 then 1 else _month + 1 end,
            _year_end,
            _today
        from
            cal
        where
            _year <= _year_end
    )

insert into @t (_sql)

--update the schedule
select
    concat('update db_sys.process_model_partitions set frequency_unit = ''',
    case 
        when cal.ddm < 0 then 'year'
        when cal.ddm < 2 then 'day'
        when cal.ddm < 4 then 'month'
    else
        'year'
    end
    ,''' where model_name = ''',p.model_name,''' and table_name = ''',p.table_name,''' and partition_name = ''',p.partition_name,'''')
from
    (select concat('SalesInvoices_P',format(cal._synonym,'00')) partition_name, datediff(month,datefromparts(_year,_month,1),_today) ddm from cal where _synonym >= 0 and _synonym < 36) cal
join
    db_sys.process_model_partitions p
on
    (
        p.model_name = 'Finance_SalesInvoices'
    and p.table_name = 'SalesInvoices'
    and p.partition_name = cal.partition_name
    )
where
    (
        case 
            when cal.ddm < 0 then 'year'
            when cal.ddm < 2 then 'day'
            when cal.ddm < 4 then 'month'
        else
            'year'
        end != p.frequency_unit
    or  p.frequency_unit is null
    )

insert into finance.SalesInvoices_auditLog (auditLog_ID, step, command)
select @auditLog_ID, step, _sql from @t

declare [0ac85761-4c23-45e6-af0b-ff7a9ab6e8a5] cursor for select _sql, step from @t

open [0ac85761-4c23-45e6-af0b-ff7a9ab6e8a5]

fetch next from [0ac85761-4c23-45e6-af0b-ff7a9ab6e8a5] into @sql, @step

while @@fetch_status = 0

begin

update finance.SalesInvoices_auditLog set stepUTCStart = getutcdate() where auditLog_ID = @auditLog_ID and step = @step

exec (@sql)

update finance.SalesInvoices_auditLog set stepUTCEnd = getutcdate() where auditLog_ID = @auditLog_ID and step = @step

fetch next from [0ac85761-4c23-45e6-af0b-ff7a9ab6e8a5] into @sql, @step

end

close [0ac85761-4c23-45e6-af0b-ff7a9ab6e8a5]
deallocate [0ac85761-4c23-45e6-af0b-ff7a9ab6e8a5]
GO
