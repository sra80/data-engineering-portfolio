CREATE VIEW [ext].[CC_timestamp]

as

select dateadd(minute,-20,db_sys.fn_getgmtdate()) [Last Update]
GO
