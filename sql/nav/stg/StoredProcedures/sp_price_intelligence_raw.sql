create or alter procedure [stg].[sp_price_intelligence_raw]
    (
        @csv_data nvarchar(max)
    )
as

set nocount on
    
truncate table stg.price_intelligence_raw

insert into stg.price_intelligence_raw (csv_data) values (@csv_data)

declare @t table ([row] int identity (0,1), [value] nvarchar(max))

declare @x table ([row] int, [column] int, [value] nvarchar(max))

declare @value nvarchar(max)

declare @row int = 1, @row_end int

insert into @t ([value])
select
    y.value
from
    stg.price_intelligence_raw x
cross apply
    string_split(x.csv_data,char(10)) y

declare w cursor for select [row], [value] from @t order by [row]

open w

fetch next from w into @row, @value

while @@fetch_status = 0

begin

    insert into @x ([row], [column], [value])
    select
        @row,
        row_number() over (order by @@fetch_status) [column],
        x.[value]
    from
        string_split(@value,'"') x

    fetch next from w into @row, @value

end

close w
deallocate w

truncate table [stg].[price_intelligence]

insert into [stg].[price_intelligence] ([PartNo], [Brand], [Category], [Price], [CompetitorPartNo], [CompetitorPrice], [CompetitorURL], [Competitor], [CompetitorTitle], [MatchType], [CompetitorStock], [CompetitorAvailability], [CompetitorRRP], [CompetitorPackSize], [CompetitorUnitSize], [CompetitorDosage])
select
    try_convert(nvarchar(64),left([2],64)) [PartNo],
    try_convert(nvarchar(64),left([4],64)) [Brand],
    try_convert(nvarchar(64),left([8],64)) [Category],
    nullif(try_convert(money,[10]),0) [Price],
    try_convert(nvarchar(64),left([12],64)) [CompetitorPartNo],
    try_convert(money,[14]) [CompetitorPrice],
    try_convert(nvarchar(255),left([16],255)) [CompetitorURL],
    try_convert(nvarchar(64),left([18],64)) [Competitor],
    try_convert(nvarchar(64),left([20],64)) [CompetitorTitle],
    try_convert(nvarchar(255),left([22],64)) [MatchType],
    try_convert(bit,left([24],64)) [CompetitorStock],
    try_convert(nvarchar(64),left([26],64)) [CompetitorAvailability],
    nullif(try_convert(money,[28]),0) [CompetitorRRP],
    try_convert(int,[30]) [CompetitorPackSize],
    ceiling(try_convert(float,[32])) [CompetitorUnitSize],
    ceiling(try_convert(float,[34])) [CompetitorDosage]
from
    (select [row], [column], [value] from @x x where [row] > 0 and [column]%2 = 0) x
pivot
    (
        max([value])
    for
        [column] in
            (
                    [2],
                    [4],
                    [8],
                    [10],
                    [12],
                    [14],
                    [16],
                    [18],
                    [20],
                    [22],
                    [24],
                    [26],
                    [28],
                    [30],
                    [32],
                    [34]
            )
    ) p
GO

GRANT EXECUTE
    ON OBJECT::[stg].[sp_price_intelligence_raw] TO [hs-bi-datawarehouse-yieldigo]
    AS [dbo];
GO
