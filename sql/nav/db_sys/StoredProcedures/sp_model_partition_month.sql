create or alter procedure [db_sys].[sp_model_partition_month]
    (
        @model_name nvarchar(64),
        @table_name nvarchar(64),
        @partition_name_prefix nvarchar(64),
        @auditLog_ID int = null
    )

as

set nocount on

declare @place_holder uniqueidentifier = newid(), @auditLog_ID_null bit = 0

if @auditLog_ID is null 

    begin

        set @auditLog_ID_null = 1
    
        exec db_sys.sp_auditLog_start @eventType = 'Procedure',@eventName='db_sys.sp_model_partition_month',@eventVersion='00',@placeHolder=@place_holder

        select @auditLog_ID = ID from db_sys.auditLog where eventDetail = convert(nvarchar(36),@place_holder)

    end



declare @t table (_sql nvarchar(max), step int identity(0,1))

declare @_sql nvarchar(max), @step int

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

, _sql as
    (
        select
            case when p.model_name is null then 
                concat
                    (
                        case when row_number() over (partition by p.model_name order by cal.partition_name) = 1 then concat('update db_sys.process_model_partitions set process = 1 where model_name = ''',@model_name,''', and table_name = ''',@table_name,''' and left(partition_name,',convert(nvarchar,len(@partition_name_prefix)),') = ''',@partition_name_prefix,'''|') end,
                        'insert into db_sys.process_model_partitions (model_name, table_name, partition_name, frequency_unit, frequency_value) values ',
                        '(''',@model_name,''',''',@table_name,''',''',cal.partition_name,''',''',
                            case 
                                when cal.ddm < 0 then 'year'
                                when cal.ddm < 2 then 'day'
                                when cal.ddm < 4 then 'month'
                            else
                                'year'
                            end
                        ,''',1)'
                    )
            else concat('update db_sys.process_model_partitions set frequency_unit = ''',
                case 
                    when cal.ddm < 0 then 'year'
                    when cal.ddm < 2 then 'day'
                    when cal.ddm < 4 then 'month'
                else
                    'year'
                end
                ,''' where model_name = ''',@model_name,''' and table_name = ''',@table_name,''' and partition_name = ''',cal.partition_name,'''')
            end _sql
        from
            (select concat(@partition_name_prefix,format(cal._synonym,'00')) partition_name, datediff(month,datefromparts(_year,_month,1),_today) ddm from cal where _synonym >= 0 and _synonym < 36) cal
        left join
            db_sys.process_model_partitions p
        on
            (
                p.model_name = @model_name
            and p.table_name = @table_name
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
    )

insert into @t (_sql)
select
    _split.value
from
    _sql
cross apply
    string_split(_sql._sql,'|') _split

declare [8411ce80-a95a-4e72-a538-3296ef5ab6a2] cursor for select _sql, step from @t

open [8411ce80-a95a-4e72-a538-3296ef5ab6a2]

fetch next from [8411ce80-a95a-4e72-a538-3296ef5ab6a2] into @_sql, @step

while @@fetch_status = 0

begin

exec (@_sql)

insert into db_sys.model_partition_month_auditLog (model_name, auditLog_ID, step, command) values (@model_name, @auditLog_ID, @step, @_sql)

fetch next from [8411ce80-a95a-4e72-a538-3296ef5ab6a2] into @_sql, @step

end

close [8411ce80-a95a-4e72-a538-3296ef5ab6a2]
deallocate [8411ce80-a95a-4e72-a538-3296ef5ab6a2]

if @auditLog_ID_null = 1 exec db_sys.sp_auditLog_end @eventDetail='Procedure Outcome: Success',@placeHolder=@place_holder
GO
