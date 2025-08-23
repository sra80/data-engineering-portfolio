create or alter procedure [price_tool_feed].[sp_pi_price_intelligence]
    (
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
    )

as

set nocount on

declare
    @product_id int,
    @row_version int = -1,
    @brand_id int,
    @match_type_id int,
    @competitor_stock bit,
    @competitor_availability_id int,
    @HS_price money = @Price,
    @compete_price money = @CompetitorPrice,
    @compete_rrp money = isnull(@CompetitorRRP,0),
    
    @competitor_id int,
    @category_id int,
    @item_id int,

    @is_changed bit = 0

set @PartNo = ltrim(rtrim(@PartNo))
set @Brand = ltrim(rtrim(@Brand))
set @Category = ltrim(rtrim(@Category))
set @CompetitorPartNo = ltrim(rtrim(@CompetitorPartNo))
set @CompetitorURL = ltrim(rtrim(@CompetitorURL))
set @Competitor = ltrim(rtrim(@Competitor))
set @CompetitorTitle = ltrim(rtrim(@CompetitorTitle))
set @MatchType = ltrim(rtrim(@MatchType))
set @CompetitorAvailability = ltrim(rtrim(@CompetitorAvailability))

select @PartNo = [1] from db_sys.string_split(@PartNo,'_')

select
    @brand_id = id
from
    price_tool_feed.pi_brand
where
    (
        brand = @brand
    )

if @brand_id is null

    begin

    insert into price_tool_feed.pi_brand (brand)
    values (@brand)

    select
        @brand_id = id
    from
        price_tool_feed.pi_brand
    where
        (
            brand = @brand
        )

    end

select
    @competitor_id = id
from
    price_tool_feed.pi_competitor
where
    (
        competitor = @Competitor
    )

if @competitor_id is null

    begin

    insert into price_tool_feed.pi_competitor (competitor)
    values (@Competitor)

    select
        @competitor_id = id
    from
        price_tool_feed.pi_competitor
    where
        (
            competitor = @Competitor
        )

    end

select
    @category_id = id
from
    price_tool_feed.pi_category
where
    (
        competitor_id = @competitor_id
    and category = @Category
    )

if @category_id is null

    begin

    insert into price_tool_feed.pi_category (competitor_id, category)
    values (@competitor_id, @Category)

    select
        @category_id = id
    from
        price_tool_feed.pi_category
    where
        (
            competitor_id = @competitor_id
        and category = @Category
        )

    end

select
    @item_id = ID
from
    ext.Item
where
    (
        company_id = @company_id
    and lower(No_) = lower(@PartNo)
    )

if @item_id is null set @item_id = -1

select
    @product_id = id
from
    price_tool_feed.pi_product
where
    (
        item_id = @item_id
    and competitor_id = @competitor_id
    and category_id = @category_id
    and partNo = @CompetitorPartNo
    and CompetitorPackSize = @CompetitorPackSize
    and CompetitorUnitSize = @CompetitorUnitSize
    and CompetitorDosage = @CompetitorDosage
    )

update price_tool_feed.pi_product set partName = @CompetitorTitle, revTS = sysdatetime() where id = @product_id and (partName != @CompetitorTitle or competitorURL != @competitorURL)

if @product_id is null

    begin

    insert into price_tool_feed.pi_product (item_id, competitor_id, category_id, partNo, partName, competitorURL, CompetitorPackSize, CompetitorUnitSize, CompetitorDosage)
    values (@item_id, @competitor_id, @category_id, @CompetitorPartNo, @CompetitorTitle, @competitorURL, @CompetitorPackSize, @CompetitorUnitSize, @CompetitorDosage)

    select
        @product_id = id
    from
        price_tool_feed.pi_product
    where
        (
            item_id = @item_id
        and competitor_id = @competitor_id
        and category_id = @category_id
        and partNo = @CompetitorPartNo
        and CompetitorPackSize = @CompetitorPackSize
        and CompetitorUnitSize = @CompetitorUnitSize
        and CompetitorDosage = @CompetitorDosage
        )

    end

select
    @match_type_id = id
from
    price_tool_feed.pi_match_type
where
    (
        match_type = @MatchType
    )

if @match_type_id is null

    begin

    insert into price_tool_feed.pi_match_type (match_type)
    values (@MatchType)

    select
        @match_type_id = id
    from
        price_tool_feed.pi_match_type
    where
        (
            match_type = @MatchType
        )

    end

if @CompetitorStock > 0 set @competitor_stock = 1 else set @competitor_stock = 0

select
    @competitor_availability_id = id
from
    price_tool_feed.pi_competitor_availability
where
    (
        competitor_availability = @CompetitorAvailability
    )

if @competitor_availability_id is null

    begin

    insert into price_tool_feed.pi_competitor_availability (competitor_availability)
    values (@CompetitorAvailability)

    select
        @competitor_availability_id = id
    from
        price_tool_feed.pi_competitor_availability
    where
        (
            competitor_availability = @CompetitorAvailability
        )

    end

select @row_version = isnull(max(row_version),-1) from price_tool_feed.pi_price_intelligence where product_id = @product_id

if @row_version = -1 set @is_changed = 1

if @is_changed = 0

    begin

    update price_tool_feed.pi_price_intelligence set is_current = 0, revTS = sysdatetime(), is_checked = 1, @is_changed = 1 where product_id = @product_id and row_version = @row_version and (match_type_id != @match_type_id or competitor_stock != @competitor_stock or competitor_availability_id != @competitor_availability_id or HS_price != @HS_price or compete_price != @compete_price or isnull(compete_rrp,0) != @compete_rrp)

    update price_tool_feed.pi_price_intelligence set is_current = 1, revTS = sysdatetime(), is_checked = 1 where product_id = @product_id and row_version = @row_version and match_type_id = @match_type_id and competitor_stock = @competitor_stock and competitor_availability_id = @competitor_availability_id and HS_price = @HS_price and compete_price = @compete_price and isnull(compete_rrp,0) = @compete_rrp

    end

if @is_changed = 1

    begin

    set @row_version += 1

    insert into price_tool_feed.pi_price_intelligence (product_id, row_version, is_current, brand_id, match_type_id, competitor_stock, competitor_availability_id, HS_price, compete_price, compete_rrp)
    values (@product_id, @row_version, 1, @brand_id, @match_type_id, @competitor_stock, @competitor_availability_id, @HS_price, @compete_price, nullif(@compete_rrp,0))


    end
GO

GRANT EXECUTE
    ON OBJECT::[price_tool_feed].[sp_pi_price_intelligence] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO
