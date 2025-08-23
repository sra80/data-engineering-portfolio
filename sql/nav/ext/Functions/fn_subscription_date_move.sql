create or alter function ext.fn_subscription_date_move
    (
        @company_id int,
        @date date
    )

returns date

as

begin

select top 1
    @date = [Move To Date]
from
    [hs_consolidated].[Subscription Date Move2] n
where 
    ( 
        company_id = @company_id
    and @date <= n.[Move From Date]
    and @date > n.[Move To Date]
    )
order by
    [Move To Date] asc

return @date

end