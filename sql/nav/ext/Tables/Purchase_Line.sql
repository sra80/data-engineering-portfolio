CREATE TABLE [ext].[Purchase_Line] (
    [ID]            INT           IDENTITY (0, 1) NOT NULL,
    [company_id]    INT           NOT NULL,
    [Document Type] INT           NOT NULL,
    [Document No_]  NVARCHAR (20) NOT NULL,
    [Line No_]      INT           NOT NULL,
    [addedTSUTC]    DATETIME2 (3) NOT NULL
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__888]
    ON [ext].[Purchase_Line]([company_id] ASC, [Document Type] ASC, [Document No_] ASC, [Line No_] ASC);
GO

ALTER TABLE [ext].[Purchase_Line]
    ADD CONSTRAINT [DF__Purchase_Line__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Purchase_Line]
    ADD CONSTRAINT [PK__Purchase_Line] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Purchase_Line]
    ADD CONSTRAINT [FK__Purchase_Line__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO
