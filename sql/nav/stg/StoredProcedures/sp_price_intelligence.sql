create or alter procedure stg.sp_price_intelligence

as

set nocount on

declare
    @PartNo nvarchar(64),
    @Brand nvarchar(64),
    @Category nvarchar(64),
    @Price money,
    @CompetitorPartNo nvarchar(64),
    @CompetitorPrice money,
    @CompetitorURL nvarchar(255),
    @Competitor nvarchar(64),
    @CompetitorTitle nvarchar(255),
    @MatchType nvarchar(64),
    @CompetitorStock bit,
    @CompetitorAvailability nvarchar(64),
    @CompetitorRRP money,
    @CompetitorPackSize int,
    @CompetitorUnitSize int,
    @CompetitorDosage int,
    @company_id int = 1

update yieldigo.pi_price_intelligence set is_checked = 0 where is_checked = 1

declare [3f4cd661-327d-4bdb-8675-d1217cac5236] cursor for select PartNo, Brand, Category, Price, CompetitorPartNo, CompetitorPrice, CompetitorURL, Competitor, CompetitorTitle, MatchType, CompetitorStock, CompetitorAvailability, CompetitorRRP, CompetitorPackSize, CompetitorUnitSize, CompetitorDosage from stg.price_intelligence

open [3f4cd661-327d-4bdb-8675-d1217cac5236]

fetch next from [3f4cd661-327d-4bdb-8675-d1217cac5236] into @PartNo, @Brand, @Category, @Price, @CompetitorPartNo, @CompetitorPrice, @CompetitorURL, @Competitor, @CompetitorTitle, @MatchType, @CompetitorStock, @CompetitorAvailability, @CompetitorRRP, @CompetitorPackSize, @CompetitorUnitSize, @CompetitorDosage

while @@fetch_status = 0

    begin

    exec yieldigo.sp_pi_price_intelligence @PartNo, @Brand, @Category, @Price, @CompetitorPartNo, @CompetitorPrice, @CompetitorURL, @Competitor, @CompetitorTitle, @MatchType, @CompetitorStock, @CompetitorAvailability, @CompetitorRRP, @CompetitorPackSize, @CompetitorUnitSize, @CompetitorDosage, @company_id
    
    fetch next from [3f4cd661-327d-4bdb-8675-d1217cac5236] into @PartNo, @Brand, @Category, @Price, @CompetitorPartNo, @CompetitorPrice, @CompetitorURL, @Competitor, @CompetitorTitle, @MatchType, @CompetitorStock, @CompetitorAvailability, @CompetitorRRP, @CompetitorPackSize, @CompetitorUnitSize, @CompetitorDosage

    end

close [3f4cd661-327d-4bdb-8675-d1217cac5236]
deallocate [3f4cd661-327d-4bdb-8675-d1217cac5236]

update yieldigo.pi_price_intelligence set is_current = 0, revTS = sysdatetime() where is_current = 1 and is_checked = 0
GO

GRANT EXECUTE
    ON OBJECT::[stg].[sp_price_intelligence] TO [hs-bi-datawarehouse-yieldigo]
    AS [dbo];
GO
