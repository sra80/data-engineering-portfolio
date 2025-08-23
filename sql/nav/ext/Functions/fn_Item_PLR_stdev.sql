create function ext.fn_Item_PLR_stdev
    (
        @closeBalance_avg int,
        @closeBalance_fct int,
        @runOut_avg date,
        @runOut_fct date
    )

returns table

as

return

select 
    stdev(x.closeBalance) stdev_closeBalance, 
    stdev(x.runOut) stdev_runOut 
from 
    (
            select 
                @closeBalance_avg closeBalance, 
                isnull(convert(int,convert(datetime,@runOut_avg)),0) runOut 
            
            union all 
            
            select 
                @closeBalance_fct, 
                isnull(convert(int,convert(datetime,@runOut_fct)),case when @closeBalance_fct is null then null else 0 end)
    ) x
GO
