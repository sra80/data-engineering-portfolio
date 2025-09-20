CREATE view db_sys.vw_auditLog_model_Marketing_SalesOrders_processTimes

as

select convert(date,eventUTCStart) d, sum(1) count_of_success, convert(decimal(4,1),round(sum(DATEDIFF(minute,eventUTCStart,eventUTCEnd))/sum(1.0),2)) avg_run_time from db_sys.auditLog where eventName = 'Marketing_SalesOrders' and eventDetail = 'Refresh Status: succeeded' group by convert(date,eventUTCStart)
GO
