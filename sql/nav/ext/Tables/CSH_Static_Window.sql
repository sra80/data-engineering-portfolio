CREATE TABLE [ext].[CSH_Static_Window] (
    [No_]          NVARCHAR (20) NOT NULL,
    [Start Date]   DATE          NOT NULL,
    [Status]       INT           NULL,
    [Last Order]   DATE          NOT NULL,
    [AddedTSUTC]   DATETIME2 (0) NOT NULL,
    [UpdatedTSUTC] DATETIME2 (0) NULL,
    [DeletedTSUTC] DATETIME2 (0) NULL
);
GO

ALTER TABLE [ext].[CSH_Static_Window]
    ADD CONSTRAINT [PK__CSH_Static_Window] PRIMARY KEY CLUSTERED ([No_] ASC, [Start Date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__E40]
    ON [ext].[CSH_Static_Window]([No_] ASC, [Last Order] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__1F7]
    ON [ext].[CSH_Static_Window]([No_] ASC, [Last Order] ASC, [Status] ASC);
GO

ALTER TABLE [ext].[CSH_Static_Window]
    ADD CONSTRAINT [DF__CSH_Static_Window__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO
