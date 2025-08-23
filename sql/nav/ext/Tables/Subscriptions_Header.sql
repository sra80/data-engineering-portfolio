CREATE TABLE [ext].[Subscriptions_Header] (
    [ID]         INT           IDENTITY (0, 1) NOT NULL,
    [company_id] INT           NOT NULL,
    [No_]        NVARCHAR (20) NOT NULL
);
GO

ALTER TABLE [ext].[Subscriptions_Header]
    ADD CONSTRAINT [FK__Subscriptions_Header__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__E95]
    ON [ext].[Subscriptions_Header]([company_id] ASC, [No_] ASC);
GO

ALTER TABLE [ext].[Subscriptions_Header]
    ADD CONSTRAINT [PK__Subscriptions_Header] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
