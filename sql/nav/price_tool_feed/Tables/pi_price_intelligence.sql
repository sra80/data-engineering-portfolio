CREATE TABLE [price_tool_feed].[pi_price_intelligence] (
    [product_id]                 INT           NOT NULL,
    [row_version]                INT           NOT NULL,
    [is_current]                 BIT           NOT NULL,
    [brand_id]                   INT           NOT NULL,
    [match_type_id]              INT           NOT NULL,
    [competitor_stock]           BIT           NOT NULL,
    [competitor_availability_id] INT           NOT NULL,
    [HS_price]                   MONEY         NULL,
    [compete_price]              MONEY         NULL,
    [compete_rrp]                MONEY         NULL,
    [addTS]                      DATETIME2 (3) NOT NULL,
    [revTS]                      DATETIME2 (3) NOT NULL,
    [is_checked]                 BIT           NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[pi_price_intelligence]
    ADD CONSTRAINT [DF__pi_price_intelligence__is_checked] DEFAULT ((1)) FOR [is_checked];
GO

ALTER TABLE [price_tool_feed].[pi_price_intelligence]
    ADD CONSTRAINT [DF__pi_price_intelligence__revTS] DEFAULT (sysdatetime()) FOR [revTS];
GO

ALTER TABLE [price_tool_feed].[pi_price_intelligence]
    ADD CONSTRAINT [DF__pi_price_intelligence__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [price_tool_feed].[pi_price_intelligence]
    ADD CONSTRAINT [PK__pi_price_intelligence] PRIMARY KEY CLUSTERED ([product_id] ASC, [row_version] ASC);
GO

GRANT UPDATE
    ON OBJECT::[price_tool_feed].[pi_price_intelligence] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

GRANT INSERT
    ON OBJECT::[price_tool_feed].[pi_price_intelligence] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__7FE]
    ON [price_tool_feed].[pi_price_intelligence]([product_id] ASC) WHERE ([is_current]=(1));
GO

ALTER TABLE [price_tool_feed].[pi_price_intelligence]
    ADD CONSTRAINT [FK__pi_price_intelligence__match_type_id] FOREIGN KEY ([match_type_id]) REFERENCES [price_tool_feed].[pi_match_type] ([id]);
GO

ALTER TABLE [price_tool_feed].[pi_price_intelligence]
    ADD CONSTRAINT [FK__pi_price_intelligence__brand_id] FOREIGN KEY ([brand_id]) REFERENCES [price_tool_feed].[pi_brand] ([id]);
GO

ALTER TABLE [price_tool_feed].[pi_price_intelligence]
    ADD CONSTRAINT [FK__pi_price_intelligence__product_id] FOREIGN KEY ([product_id]) REFERENCES [price_tool_feed].[pi_product] ([id]);
GO