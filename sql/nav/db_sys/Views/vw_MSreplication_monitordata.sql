
CREATE view [db_sys].[vw_MSreplication_monitordata]

as

select publication [Publication], db_sys.fn_datediff_string(getutcdate(),dateadd(second,cur_latency,getutcdate()),1) [Latency], db_sys.fn_datediff_string(addTS,getutcdate(),1) + ' ago' [Last Status Update] from [distribution].MSreplication_monitordata where agent_type = 3
GO
