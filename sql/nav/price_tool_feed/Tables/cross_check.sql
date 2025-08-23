CREATE TABLE [price_tool_feed].[cross_check] (
    [month]          DATE          NOT NULL,
    [category_id]    INT           NOT NULL,
    [store_id]       INT           NOT NULL,
    [total_quantity] INT           NOT NULL,
    [total_revenue]  MONEY         NOT NULL,
    [total_profit]   MONEY         NOT NULL,
    [addTS]          DATETIME2 (3) NOT NULL,
    [revTS]          DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[cross_check]
    ADD CONSTRAINT [DF__cross_check__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [price_tool_feed].[cross_check]
    ADD CONSTRAINT [DF__cross_check__revTS] DEFAULT (sysdatetime()) FOR [revTS];
GO

ALTER TABLE [price_tool_feed].[cross_check]
    ADD CONSTRAINT [PK__cross_check] PRIMARY KEY CLUSTERED ([month] ASC, [category_id] ASC, [store_id] ASC);
GO
