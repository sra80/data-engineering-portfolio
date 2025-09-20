create or alter function db_sys.fn_date_ret_null
    (
        @date datetime
    )

returns datetime

as

begin

return nullif(@date,datefromparts(1753,1,1))

end