CREATE TABLE [price_tool_feed].[pi_price_position] (
    [id]       INT           IDENTITY (1, 1) NOT NULL,
    [position] NVARCHAR (64) NOT NULL,
    [addTS]    DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[pi_price_position]
    ADD CONSTRAINT [DF__pi_price_position__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__693]
    ON [price_tool_feed].[pi_price_position]([position] ASC);
GO

ALTER TABLE [price_tool_feed].[pi_price_position]
    ADD CONSTRAINT [PK__pi_price_position] PRIMARY KEY CLUSTERED ([id] ASC);
GO

GRANT INSERT
    ON OBJECT::[price_tool_feed].[pi_price_position] TO [hs-bi-datawarehouse-price_tool_feed]
    AS [dbo];
GO
