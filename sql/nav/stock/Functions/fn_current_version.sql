create or alter function stock.fn_current_version
    (

    )

returns int

as

begin

declare @cv int = (select row_version from stock.forecast_subscriptions_version where is_current = 1)

return @cv

end