CREATE TABLE [price_tool_feed].[sales_all] (
    [id]          INT           NOT NULL,
    [store_id]    INT           NOT NULL,
    [article_id]  INT           NOT NULL,
    [date]        DATE          NOT NULL,
    [price_type]  TINYINT       NOT NULL,
    [quantity]    INT           NOT NULL,
    [price]       MONEY         NOT NULL,
    [shelf_price] MONEY         NOT NULL,
    [cost_price]  MONEY         NOT NULL,
    [customer_id] INT           NOT NULL,
    [addTS]       DATETIME2 (3) NOT NULL,
    [revTS]       DATETIME2 (3) NOT NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__F24]
    ON [price_tool_feed].[sales_all]([article_id] ASC, [date] ASC)
    INCLUDE([store_id], [price_type], [quantity], [price], [shelf_price], [cost_price], [customer_id]);
GO

CREATE NONCLUSTERED INDEX [IX__137]
    ON [price_tool_feed].[sales_all]([article_id] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__792]
    ON [price_tool_feed].[sales_all]([date] ASC)
    INCLUDE([store_id], [article_id], [price_type], [quantity], [price], [shelf_price], [cost_price], [customer_id]);
GO

ALTER TABLE [price_tool_feed].[sales_all]
    ADD CONSTRAINT [PK__sales_all] PRIMARY KEY CLUSTERED ([id] ASC);
GO

ALTER TABLE [price_tool_feed].[sales_all]
    ADD CONSTRAINT [DF__sales_all__yieldigo__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [price_tool_feed].[sales_all]
    ADD CONSTRAINT [DF__sales_all__revTS] DEFAULT (sysdatetime()) FOR [revTS];
GO
