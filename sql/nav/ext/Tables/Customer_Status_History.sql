CREATE TABLE [ext].[Customer_Status_History] (
    [No_]                              NVARCHAR (20) NOT NULL,
    [Start Date]                       DATE          NOT NULL,
    [Status]                           INT           NULL,
    [Last Order]                       DATE          NOT NULL,
    [AddedTSUTC]                       DATETIME2 (0) NOT NULL,
    [UpdatedTSUTC]                     DATETIME2 (0) NULL,
    [DeletedTSUTC]                     DATETIME2 (0) NULL,
    [End Date]                         DATE          NULL,
    [Merged_CSH_Moving_Extended_TSUTC] DATETIME2 (0) NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__932]
    ON [ext].[Customer_Status_History]([No_] ASC, [Last Order] ASC, [Status] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__4CA]
    ON [ext].[Customer_Status_History]([No_] ASC, [Last Order] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__FD5]
    ON [ext].[Customer_Status_History]([No_] ASC, [Last Order] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__ECA]
    ON [ext].[Customer_Status_History]([End Date] ASC, [Status] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__152]
    ON [ext].[Customer_Status_History]([No_] ASC, [Start Date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__1E1]
    ON [ext].[Customer_Status_History]([End Date] ASC);
GO

ALTER TABLE [ext].[Customer_Status_History]
    ADD CONSTRAINT [PK__Customer_Status_History] PRIMARY KEY CLUSTERED ([No_] ASC, [Start Date] ASC);
GO

ALTER TABLE [ext].[Customer_Status_History]
    ADD CONSTRAINT [DF__Customer_Status_History__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO
