DROP TABLE IF EXISTS [price_tool_feed].[pi_product]
GO

CREATE TABLE [price_tool_feed].[pi_product] (
    [id]                    INT            IDENTITY (1, 1) NOT NULL,
    [item_id]               INT            NOT NULL,
    [competitor_id]         INT            NOT NULL,
    [category_id]           INT            NOT NULL,
    [partNo]                NVARCHAR (64)  NULL,
    [CompetitorPackSize]    INT            NOT NULL,
    [CompetitorUnitSize]    INT            NOT NULL,
    [CompetitorDosage]      INT            NOT NULL,
    [partName]              NVARCHAR (64) NULL,
    [competitorURL]         NVARCHAR (255) NOT NULL,
    [addTS]                 DATETIME2 (3)  NOT NULL,
    [revTS]                 DATETIME2 (3)  NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[pi_product]
    ADD CONSTRAINT [FK__pi_product__competitor_id] FOREIGN KEY ([competitor_id]) REFERENCES [price_tool_feed].[pi_competitor] ([id]);
GO

ALTER TABLE [price_tool_feed].[pi_product]
    ADD CONSTRAINT [FK__pi_product__category_id] FOREIGN KEY ([category_id]) REFERENCES [price_tool_feed].[pi_category] ([id]);
GO

ALTER TABLE [price_tool_feed].[pi_product]
    ADD CONSTRAINT [PK__pi_product] PRIMARY KEY CLUSTERED ([id] ASC);
GO

GRANT INSERT
    ON OBJECT::[price_tool_feed].[pi_product] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

GRANT UPDATE
    ON OBJECT::[price_tool_feed].[pi_product] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__406]
    ON [price_tool_feed].[pi_product]([item_id] ASC, [competitor_id] ASC, [category_id] ASC, [partNo] ASC, [CompetitorPackSize] ASC, [CompetitorUnitSize] ASC, [CompetitorDosage] ASC);
GO

ALTER TABLE [price_tool_feed].[pi_product]
    ADD CONSTRAINT [DF__pi_product__revTS] DEFAULT (sysdatetime()) FOR [revTS];
GO

ALTER TABLE [price_tool_feed].[pi_product]
    ADD CONSTRAINT [DF__pi_product__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [price_tool_feed].[pi_product]
    ADD CONSTRAINT [DF__pi_product__CompetitorPackSize] DEFAULT (0) FOR [CompetitorPackSize];
GO

ALTER TABLE [price_tool_feed].[pi_product]
    ADD CONSTRAINT [DF__pi_product__CompetitorUnitSize] DEFAULT (0) FOR [CompetitorUnitSize];
GO

ALTER TABLE [price_tool_feed].[pi_product]
    ADD CONSTRAINT [DF__pi_product__CompetitorDosage] DEFAULT (0) FOR [CompetitorDosage];
GO