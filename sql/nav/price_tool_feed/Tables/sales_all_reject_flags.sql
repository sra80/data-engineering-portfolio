CREATE TABLE [price_tool_feed].[sales_all_reject_flags] (
    [id] INT NOT NULL,
    [0]  BIT NOT NULL,
    [1]  BIT NOT NULL,
    [2]  BIT NOT NULL,
    [3]  BIT NOT NULL,
    [4]  BIT NOT NULL,
    [5]  BIT NOT NULL
);
GO

ALTER TABLE [price_tool_feed].[sales_all_reject_flags]
    ADD CONSTRAINT [DF__sales_all_reject_flags__2] DEFAULT ((0)) FOR [2];
GO

ALTER TABLE [price_tool_feed].[sales_all_reject_flags]
    ADD CONSTRAINT [DF__sales_all_reject_flags__1] DEFAULT ((0)) FOR [1];
GO

ALTER TABLE [price_tool_feed].[sales_all_reject_flags]
    ADD CONSTRAINT [DF__sales_all_reject_flags__4] DEFAULT ((0)) FOR [4];
GO

ALTER TABLE [price_tool_feed].[sales_all_reject_flags]
    ADD CONSTRAINT [DF__sales_all_reject_flags__5] DEFAULT ((0)) FOR [5];
GO

ALTER TABLE [price_tool_feed].[sales_all_reject_flags]
    ADD CONSTRAINT [DF__sales_all_reject_flags__0] DEFAULT ((0)) FOR [0];
GO

ALTER TABLE [price_tool_feed].[sales_all_reject_flags]
    ADD CONSTRAINT [DF__sales_all_reject_flags__3] DEFAULT ((0)) FOR [3];
GO

ALTER TABLE [price_tool_feed].[sales_all_reject_flags]
    ADD CONSTRAINT [PK__sales_all_reject_flags] PRIMARY KEY CLUSTERED ([id] ASC);
GO
