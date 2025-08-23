create or alter procedure [forecast_feed].[sp_sales_rebuilds]
    (
        @place_holder_session uniqueidentifier = null
    )

as

set nocount on

if @place_holder_session is null set @place_holder_session = newid()

declare @begin date = datefromparts(year(getutcdate())-2,1,1)

declare @key_date int = datepart(year,@begin)*100 + datepart(week,@begin)

while @begin < getutcdate()

begin

    exec forecast_feed.sp_sales @recomp_year_week = @key_date, @run_id = @place_holder_session

    set @begin = dateadd(week,1,@begin)

    set @key_date= datepart(year,@begin)*100 + datepart(week,@begin)

end