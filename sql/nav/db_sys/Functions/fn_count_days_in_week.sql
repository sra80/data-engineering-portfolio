CREATE function db_sys.fn_count_days_in_week
     (
         @date date
     )
 
 returns tinyint
 
 as
 
 begin
 
 return datediff(day,db_sys.foweek(@date,0), (select case when year(db_sys.foweek(dateadd(week,1,@date),0)) > year(@date) then datefromparts(year(@date)+1,1,1) else db_sys.foweek(dateadd(week,1,@date),0) end))
 
 end
GO
