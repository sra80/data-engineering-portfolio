create function db_sys.fn_getgmtdate () returns datetime2 as begin return dateadd(hour,datediff(hour,sysdatetime() at time zone 'GMT Standard Time',sysdatetime()),sysdatetime()) end
GO
