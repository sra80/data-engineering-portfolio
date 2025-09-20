create or alter function db_sys.fn_datetime_utc_to_gmt
    (
        @utc_datetime2 datetime2 = null
    )

returns datetime2

as

begin

return dateadd(minute,datediff(minute,sysdatetime() at time zone 'GMT Standard Time',sysdatetime()),isnull(@utc_datetime2,getutcdate()))

end
GO
