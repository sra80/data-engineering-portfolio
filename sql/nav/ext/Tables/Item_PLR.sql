CREATE TABLE [ext].[Item_PLR] (
    [sku]                    NVARCHAR (32)   NOT NULL,
    [batchNo]                NVARCHAR (32)   NOT NULL,
    [country]                NVARCHAR (2)    NOT NULL,
    [distribution_type]      NVARCHAR (32)   NOT NULL,
    [row_version]            INT             NOT NULL,
    [is_current]             BIT             NOT NULL,
    [openBalance]            INT             NOT NULL,
    [closeBalance]           INT             NOT NULL,
    [runOut]                 DATE            NULL,
    [avgSalesDaily]          DECIMAL (12, 6) NOT NULL,
    [unitCost]               DECIMAL (12, 6) NOT NULL,
    [firstSale]              DATE            NULL,
    [endDate]                DATE            NOT NULL,
    [dateaddedUTC]           DATETIME2 (1)   NOT NULL,
    [close_balance_forecast] INT             NULL,
    [runOut_forecast]        DATE            NULL,
    [forcastSalesDaily]      DECIMAL (12, 6) NULL
);
GO

ALTER TABLE [ext].[Item_PLR]
    ADD CONSTRAINT [PK__Item_PLR] PRIMARY KEY CLUSTERED ([sku] ASC, [batchNo] ASC, [country] ASC, [distribution_type] ASC, [row_version] ASC);
GO

ALTER TABLE [ext].[Item_PLR]
    ADD CONSTRAINT [DF__Item_PLR__dateaddedUTC] DEFAULT (getutcdate()) FOR [dateaddedUTC];
GO
