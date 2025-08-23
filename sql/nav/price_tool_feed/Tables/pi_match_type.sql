CREATE TABLE [price_tool_feed].[pi_match_type] (
    [id]         INT           IDENTITY (1, 1) NOT NULL,
    [match_type] NVARCHAR (64) NOT NULL,
    [addTS]      DATETIME2 (3) NOT NULL
);
GO

GRANT INSERT
    ON OBJECT::[price_tool_feed].[pi_match_type] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO

ALTER TABLE [price_tool_feed].[pi_match_type]
    ADD CONSTRAINT [PK__pi_match_type] PRIMARY KEY CLUSTERED ([id] ASC);
GO

ALTER TABLE [price_tool_feed].[pi_match_type]
    ADD CONSTRAINT [DF__pi_match_type__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__B9F]
    ON [price_tool_feed].[pi_match_type]([match_type] ASC);
GO
