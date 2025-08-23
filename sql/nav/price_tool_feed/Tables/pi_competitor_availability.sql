CREATE TABLE [price_tool_feed].[pi_competitor_availability] (
    [id]                      INT            IDENTITY (1, 1) NOT NULL,
    [competitor_availability] NVARCHAR (255) NOT NULL,
    [addTS]                   DATETIME2 (3)  NOT NULL
);
GO

GRANT INSERT
    ON OBJECT::[price_tool_feed].[pi_competitor_availability] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

ALTER TABLE [price_tool_feed].[pi_competitor_availability]
    ADD CONSTRAINT [DF__pi_competitor_availability__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__8B6]
    ON [price_tool_feed].[pi_competitor_availability]([competitor_availability] ASC);
GO

ALTER TABLE [price_tool_feed].[pi_competitor_availability]
    ADD CONSTRAINT [PK__pi_competitor_availability] PRIMARY KEY CLUSTERED ([id] ASC);
GO
