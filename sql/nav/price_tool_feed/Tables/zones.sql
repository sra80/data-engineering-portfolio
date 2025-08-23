CREATE TABLE [price_tool_feed].[zones] (
    [zone_id]   INT           IDENTITY (1, 1) NOT NULL,
    [zone_name] NVARCHAR (32) NOT NULL,
    [addTS]     DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[zones]
    ADD CONSTRAINT [DF__zones__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [price_tool_feed].[zones]
    ADD CONSTRAINT [PK__zones] PRIMARY KEY CLUSTERED ([zone_id] ASC);
GO
