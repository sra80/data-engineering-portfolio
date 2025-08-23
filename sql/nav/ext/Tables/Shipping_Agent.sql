CREATE TABLE [ext].[Shipping_Agent] (
    [ID]             INT           IDENTITY (0, 1) NOT NULL,
    [company_id]     INT           NOT NULL,
    [shipping_agent] NVARCHAR (10) NOT NULL,
    [addedTSUTC]     DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[Shipping_Agent]
    ADD CONSTRAINT [PK__Shipping_Agent] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Shipping_Agent]
    ADD CONSTRAINT [FK__Shipping_Agent__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Shipping_Agent]
    ADD CONSTRAINT [DF__Shipping_Agent__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO
