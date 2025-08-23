CREATE TABLE [stg].[price_intelligence_raw] (
    [csv_data] NVARCHAR (MAX) NULL,
    [addTS]    DATETIME2 (3)  NOT NULL
);
GO

GRANT INSERT
    ON OBJECT::[stg].[price_intelligence_raw] TO [hs-bi-datawarehouse-yieldigo]
    AS [dbo];
GO

GRANT ALTER
    ON OBJECT::[stg].[price_intelligence_raw] TO [hs-bi-datawarehouse-yieldigo]
    AS [dbo];
GO

ALTER TABLE [stg].[price_intelligence_raw]
    ADD CONSTRAINT [DF__price_intelligence_raw__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO
