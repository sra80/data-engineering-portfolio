CREATE TABLE [ext].[Item_OOS] (
    [sku]                 NVARCHAR (32) NOT NULL,
    [row_version]         INT           NOT NULL,
    [is_current]          BIT           NOT NULL,
    [country]             NVARCHAR (2)  NOT NULL,
    [distribution_type]   NVARCHAR (32) NOT NULL,
    [openBalance]         INT           NOT NULL,
    [availableStock]      INT           NOT NULL,
    [onOrder]             INT           NOT NULL,
    [forecastQty]         INT           NOT NULL,
    [ringFenceQty]        INT           NOT NULL,
    [subQty]              INT           NOT NULL,
    [awaitingQAQty]       INT           NOT NULL,
    [lastSale]            DATE          NULL,
    [lastPick]            DATE          NULL,
    [forecastRunoutDate]  DATE          NULL,
    [ringFenceRunout]     DATE          NULL,
    [estStockInRef]       NVARCHAR (32) NULL,
    [estStockIn]          DATE          NULL,
    [estStockInQty]       INT           NULL,
    [ringFenceItemCard]   DATE          NULL,
    [ringFenceActionDate] DATE          NULL,
    [dateaddedUTC]        DATETIME2 (1) NOT NULL
);
GO

ALTER TABLE [ext].[Item_OOS]
    ADD CONSTRAINT [PK__Item_OOS] PRIMARY KEY CLUSTERED ([sku] ASC, [row_version] ASC);
GO

ALTER TABLE [ext].[Item_OOS]
    ADD CONSTRAINT [DF__Item_OOS__dateaddedUTC] DEFAULT (getutcdate()) FOR [dateaddedUTC];
GO
