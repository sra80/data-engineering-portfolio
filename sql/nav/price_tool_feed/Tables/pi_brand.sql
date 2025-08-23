CREATE TABLE [price_tool_feed].[pi_brand] (
    [id]    INT           IDENTITY (1, 1) NOT NULL,
    [brand] NVARCHAR (64) NOT NULL,
    [addTS] DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[pi_brand]
    ADD CONSTRAINT [DF__pi_brand__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

GRANT INSERT
    ON OBJECT::[price_tool_feed].[pi_brand] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__61B]
    ON [price_tool_feed].[pi_brand]([brand] ASC);
GO

ALTER TABLE [price_tool_feed].[pi_brand]
    ADD CONSTRAINT [PK__pi_brand] PRIMARY KEY CLUSTERED ([id] ASC);
GO
