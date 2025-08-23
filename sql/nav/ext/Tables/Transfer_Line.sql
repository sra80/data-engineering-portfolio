CREATE TABLE [ext].[Transfer_Line] (
    [ID]           INT           IDENTITY (0, 1) NOT NULL,
    [company_id]   INT           NOT NULL,
    [Document No_] NVARCHAR (20) NOT NULL,
    [Line No_]     INT           NOT NULL,
    [addedTSUTC]   DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [ext].[Transfer_Line]
    ADD CONSTRAINT [DF__Transfer_Line__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Transfer_Line]
    ADD CONSTRAINT [PK__Transfer_Line] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Transfer_Line]
    ADD CONSTRAINT [FK__Transfer_Line__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__A82]
    ON [ext].[Transfer_Line]([company_id] ASC, [Document No_] ASC, [Line No_] ASC);
GO
