CREATE TABLE [ext].[Media_Code] (
    [ID]         INT           IDENTITY (0, 1) NOT NULL,
    [company_id] INT           NOT NULL,
    [media_code] NVARCHAR (10) NOT NULL,
    [addedTSUTC] DATETIME2 (0) NOT NULL
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__776]
    ON [ext].[Media_Code]([company_id] ASC, [media_code] ASC);
GO

ALTER TABLE [ext].[Media_Code]
    ADD CONSTRAINT [DF__Media_Code__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Media_Code]
    ADD CONSTRAINT [FK__Media_Code__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Media_Code]
    ADD CONSTRAINT [PK__Media_Code] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
