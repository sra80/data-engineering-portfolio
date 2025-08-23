create or alter function db_sys.fn_datetime_gmt_to_utc
    (
        @utc_datetime2 datetime2 = null
    )

returns datetime2

as

begin

return dateadd(minute,datediff(minute,sysdatetime(),sysdatetime() at time zone 'GMT Standard Time'),isnull(@utc_datetime2,getutcdate()))

end
GO
