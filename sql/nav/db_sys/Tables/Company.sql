CREATE TABLE [db_sys].[Company] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [NAV_DB]      NVARCHAR (32) NOT NULL,
    [Company]     NVARCHAR (32) NOT NULL,
    [addedTSUTC]  DATETIME2 (0) NOT NULL,
    [is_excluded] BIT           NOT NULL,
    [is_insightInc] BIT           NOT NULL,
    [Country]     NVARCHAR (2)  NOT NULL,
    [code]        NVARCHAR (4)  NOT NULL
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__5EF]
    ON [db_sys].[Company]([Company] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__4FB]
    ON [db_sys].[Company]([NAV_DB] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__459]
    ON [db_sys].[Company]([code] ASC);
GO

ALTER TABLE [db_sys].[Company]
    ADD CONSTRAINT [DF__Company__is_excluded] DEFAULT ((0)) FOR [is_excluded];
GO

ALTER TABLE [db_sys].[Company]
    ADD CONSTRAINT [DF__Company__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [db_sys].[Company]
    ADD CONSTRAINT [DF__Company__is_insightInc] DEFAULT ((0)) FOR [is_insightInc];
GO

ALTER TABLE [db_sys].[Company]
    ADD CONSTRAINT [PK__Company] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
