CREATE TABLE [price_tool_feed].[pi_category] (
    [id]            INT           IDENTITY (1, 1) NOT NULL,
    [competitor_id] INT           NOT NULL,
    [category]      NVARCHAR (64) NOT NULL,
    [addTS]         DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[pi_category]
    ADD CONSTRAINT [PK__pi_category] PRIMARY KEY CLUSTERED ([id] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__3D2]
    ON [price_tool_feed].[pi_category]([competitor_id] ASC, [category] ASC);
GO

ALTER TABLE [price_tool_feed].[pi_category]
    ADD CONSTRAINT [DF__pi_category__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

GRANT INSERT
    ON OBJECT::[price_tool_feed].[pi_category] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

ALTER TABLE [price_tool_feed].[pi_category]
    ADD CONSTRAINT [FK__pi_category__competitor_id] FOREIGN KEY ([competitor_id]) REFERENCES [price_tool_feed].[pi_competitor] ([id]);
GO
