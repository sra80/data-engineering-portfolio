CREATE TABLE [stock].[StockManagement_Archive] (
    [company_id]            INT              NOT NULL,
    [country_id]            INT              NOT NULL,
    [key_posting_date]      DATE             NOT NULL,
    [opt_key]               INT              NOT NULL,
    [is_amazon]             INT              NOT NULL,
    [key_DocumentType]      INT              NOT NULL,
    [key_location]          INT              NOT NULL,
    [key_batch]             INT              NOT NULL,
    [Quantity]              DECIMAL (38, 20) NOT NULL,
    [Cost Actual]           FLOAT (53)       NOT NULL,
    [Cost Expected]         FLOAT (53)       NOT NULL,
    [Cost Posted to G_L]    FLOAT (53)       NOT NULL,
    [Sales Amount (Actual)] FLOAT (53)       NOT NULL,
    [Discount Amount]       FLOAT (53)       NOT NULL,
    [updateTS]              DATETIME2 (0)    NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__211]
    ON [stock].[StockManagement_Archive]([key_posting_date] ASC);
GO

ALTER TABLE [stock].[StockManagement_Archive]
    ADD CONSTRAINT [PK__StockManagement_Archive] PRIMARY KEY CLUSTERED ([company_id] ASC, [country_id] ASC, [key_posting_date] ASC, [opt_key] ASC, [is_amazon] ASC, [key_DocumentType] ASC, [key_location] ASC, [key_batch] ASC);
GO

ALTER TABLE [stock].[StockManagement_Archive]
    ADD CONSTRAINT [DF__StockManagement_Archive__updateTS] DEFAULT getutcdate() FOR updateTS
GO


