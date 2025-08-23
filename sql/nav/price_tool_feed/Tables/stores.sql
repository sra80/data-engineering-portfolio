CREATE TABLE [price_tool_feed].[stores] (
    [store_id]    INT           IDENTITY (1, 1) NOT NULL,
    [zone_id]     INT           NOT NULL,
    [store_name]  NVARCHAR (32) NOT NULL,
    [platform_id] INT           NULL,
    [customer_id] INT           NULL,
    [is_sub]      BIT           NOT NULL,
    [is_ss1]      BIT           NOT NULL,
    [is_online]   BIT           NOT NULL,
    [addTS]       DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[stores]
    ADD CONSTRAINT [PK__stores] PRIMARY KEY CLUSTERED ([store_id] ASC);
GO

ALTER TABLE [price_tool_feed].[stores]
    ADD CONSTRAINT [DF__stores__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [price_tool_feed].[stores]
    ADD CONSTRAINT [FK__stores__zone_id] FOREIGN KEY ([zone_id]) REFERENCES [price_tool_feed].[zones] ([zone_id]);
GO

