create or alter function db_sys.fn_model_partition_month
    (
        @date date
    )

returns int

as

begin

return datediff(month,datefromparts(year(getutcdate())-2,1,1),@date)

end