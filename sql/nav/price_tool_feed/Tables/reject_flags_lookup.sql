CREATE TABLE [price_tool_feed].[reject_flags_lookup] (
    [id]         INT            IDENTITY (0, 1) NOT NULL,
    [criteria]   NVARCHAR (MAX) NULL,
    [definition] NVARCHAR (MAX) NULL
);
GO

ALTER TABLE [price_tool_feed].[reject_flags_lookup]
    ADD CONSTRAINT [PK__sales_rejected_reason] PRIMARY KEY CLUSTERED ([id] ASC);
GO
