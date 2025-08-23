create or alter view [marketing].[timestamp]

as

select
    'ext.sp_sales_item_doubles' task,
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),(select last_processed from db_sys.procedure_schedule where procedureName = 'ext.sp_sales_item_doubles')) ts,
    tz.[name] timezone,
    tz.current_utc_offset,
    tz.is_currently_dst,
    uc.username
from
    sys.time_zone_info tz
left join
    db_sys.user_config uc
on  
    (
        tz.[name] = uc.timezone collate database_default
    )

union all

select
    'Product Lifespan' task,
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),(select last_processed from db_sys.process_model_partitions where model_name = 'Marketing_SalesOrders' and table_name = 'Product Lifespan' and partition_name = 'Partition')) ts,
    tz.[name] timezone,
    tz.current_utc_offset,
    tz.is_currently_dst,
    uc.username
from
    sys.time_zone_info tz
left join
    db_sys.user_config uc
on  
    (
        tz.[name] = uc.timezone collate database_default
    )
GO