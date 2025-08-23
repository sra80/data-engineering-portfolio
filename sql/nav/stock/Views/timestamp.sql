create or alter view [stock].[timestamp]

as

select 
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),getutcdate()) ts_now,
	dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),(select min(ts) ts from (select max(dateaddedUTC) ts from ext.Item_OOS where is_current = 1 union all select last_processed from db_sys.process_model_partitions where model_name = 'Logistics_StockManagement' and table_name = 'Forecast' and partition_name = 'OOS_Forecast')x)) ts_oos,
	dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),(select min(ts) ts from (select max(dateaddedUTC) ts from ext.Item_PLR where is_current = 1 union all select last_processed from db_sys.process_model_partitions where model_name = 'Logistics_StockManagement' and table_name = 'Product Lifetime Risk' and partition_name = 'Product Lifetime Risk')x)) ts_plr,
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),(select min(ts) ts from (select max(reviewedTSUTC) ts from ext.Item_UnitCost where is_current = 1 union all select last_processed from db_sys.process_model_partitions where model_name = 'Logistics_StockManagement' and table_name = 'Products' and partition_name = 'Products')x)) ts_iuc,
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate()),(select min(ts) ts from (select max(reviewedTSUTC) ts from ext.Item_UnitCost where is_current = 1 union all select last_processed from db_sys.process_model_partitions where model_name = 'Logistics_StockManagement' and table_name = 'Forecast Stock' and partition_name = 'Forecast_Stock')x)) ts_fss,
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate() at TIME ZONE 'GMT Standard Time'),(select max(reviewedTSUTC) ts from [anaplan].forecast)) ts_nav_forecast,
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate() at TIME ZONE 'GMT Standard Time'),(select (select max(ts) from (values(fsv.addTS_start),(fsv.rv_sub_TS),(fsv.intraday_TS)) as value(ts)) ts from stock.forecast_subscriptions_version fsv where fsv.row_version = (select row_version from stock.forecast_subscriptions_version where is_current = 1))) ts_oos_anaplan,
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate() at TIME ZONE 'GMT Standard Time'),(select (select max(ts) from (values(fsv.addTS_start),(fsv.rv_sub_TS)) as value(ts)) ts from stock.forecast_subscriptions_version fsv where fsv.row_version = (select row_version from stock.forecast_subscriptions_version where is_current = 1))) ts_plr_anaplan,
    dateadd(minute,datediff(minute,getutcdate() at TIME ZONE tz.[name],getutcdate() at TIME ZONE 'GMT Standard Time'),(select last_processed from db_sys.procedure_schedule where procedureName = 'ext.sp_Item_UnitCost')) ts_item_unitcost,
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
