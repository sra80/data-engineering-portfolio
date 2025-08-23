CREATE TABLE [ext].[Customer_Item_Summary] (
    [cus]          NVARCHAR (32) NOT NULL,
    [sku]          NVARCHAR (32) NOT NULL,
    [units]        INT           NOT NULL,
    [gross]        MONEY         NOT NULL,
    [net]          MONEY         NOT NULL,
    [first_order]  DATE          NOT NULL,
    [last_order]   DATE          NOT NULL,
    [AddedTSUTC]   DATETIME2 (0) NOT NULL,
    [UpdatedTSUTC] DATETIME2 (0) NULL
);
GO

ALTER TABLE [ext].[Customer_Item_Summary]
    ADD CONSTRAINT [DF__Customer_Item_Summary__gross] DEFAULT ((0)) FOR [gross];
GO

ALTER TABLE [ext].[Customer_Item_Summary]
    ADD CONSTRAINT [DF__Customer_Item_Summary__units] DEFAULT ((0)) FOR [units];
GO

ALTER TABLE [ext].[Customer_Item_Summary]
    ADD CONSTRAINT [DF__Customer_Item_Summary__net] DEFAULT ((0)) FOR [net];
GO

ALTER TABLE [ext].[Customer_Item_Summary]
    ADD CONSTRAINT [DF__Customer_Item_Summary__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO

ALTER TABLE [ext].[Customer_Item_Summary]
    ADD CONSTRAINT [PK__Customer_Item_Summary] PRIMARY KEY CLUSTERED ([cus] ASC, [sku] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__88D]
    ON [ext].[Customer_Item_Summary]([cus] ASC, [sku] ASC, [last_order] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__D4B]
    ON [ext].[Customer_Item_Summary]([cus] ASC, [sku] ASC, [first_order] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__756]
    ON [ext].[Customer_Item_Summary]([cus] ASC, [first_order] ASC);
GO
