CREATE TABLE [price_tool_feed].[pi_competitor] (
    [id]         INT           IDENTITY (1, 1) NOT NULL,
    [competitor] NVARCHAR (64) NOT NULL,
    [addTS]      DATETIME2 (3) NOT NULL
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__854]
    ON [price_tool_feed].[pi_competitor]([competitor] ASC);
GO

GRANT INSERT
    ON OBJECT::[price_tool_feed].[pi_competitor] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

ALTER TABLE [price_tool_feed].[pi_competitor]
    ADD CONSTRAINT [PK__pi_Competitor] PRIMARY KEY CLUSTERED ([id] ASC);
GO

ALTER TABLE [price_tool_feed].[pi_competitor]
    ADD CONSTRAINT [DF__pi_competitor__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO
