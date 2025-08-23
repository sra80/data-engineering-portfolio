DROP TABLE IF EXISTS [stg].[price_intelligence]
GO

CREATE TABLE [stg].[price_intelligence] (
    [PartNo]                 NVARCHAR (64)  NULL,
    [Brand]                  NVARCHAR (64)  NULL,
    [Category]               NVARCHAR (64)  NULL,
    [Price]                  MONEY          NULL,
    [CompetitorPartNo]       NVARCHAR (64)  NULL,
    [CompetitorPrice]        MONEY          NULL,
    [CompetitorURL]          NVARCHAR (255) NULL,
    [Competitor]             NVARCHAR (64)  NULL,
    [CompetitorTitle]        NVARCHAR (64) NULL,
    [MatchType]              NVARCHAR (64)  NULL,
    [CompetitorStock]        BIT            NULL,
    [CompetitorAvailability] NVARCHAR (64)  NULL,
    [CompetitorRRP]          MONEY          NULL,
    [CompetitorPackSize]     INT            NULL,
    [CompetitorUnitSize]     INT            NULL,
    [CompetitorDosage]       INT            NULL
);
GO

GRANT ALTER
    ON OBJECT::[stg].[price_intelligence] TO [hs-bi-datawarehouse-yieldigo]
    AS [dbo];
GO
