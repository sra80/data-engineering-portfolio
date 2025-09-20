create or alter function db_sys.fn_datetime_utc_to_cest
    (
        @utc_datetime2 datetime2
    )

returns datetime2

as

begin

return dateadd(minute,datediff(minute,sysdatetime() at time zone 'Central European Standard Time',sysdatetime()),@utc_datetime2)

end
GO