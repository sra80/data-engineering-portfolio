CREATE TABLE [ext].[Campaign] (
    [ID]            INT           IDENTITY (0, 1) NOT NULL,
    [company_id]    INT           NOT NULL,
    [campaign_code] NVARCHAR (20) NOT NULL,
    [addedTSUTC]    DATETIME2 (0) NULL
);
GO

ALTER TABLE [ext].[Campaign]
    ADD CONSTRAINT [DF__Campaign__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__B0E]
    ON [ext].[Campaign]([company_id] ASC, [campaign_code] ASC);
GO

ALTER TABLE [ext].[Campaign]
    ADD CONSTRAINT [FK__Campaign__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Campaign]
    ADD CONSTRAINT [PK__Campaign] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
