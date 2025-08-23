CREATE TABLE [ext].[Country_Region] (
    [ID]           INT           IDENTITY (0, 1) NOT NULL,
    [company_id]   INT           NOT NULL,
    [country_code] NVARCHAR (10) NOT NULL,
    [addedTSUTC]   DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[Country_Region]
    ADD CONSTRAINT [PK__Country_Region] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Country_Region]
    ADD CONSTRAINT [DF__Country_Region__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__7FC]
    ON [ext].[Country_Region]([company_id] ASC, [country_code] ASC);
GO
