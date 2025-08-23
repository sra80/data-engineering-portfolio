CREATE TABLE [ext].[Return_Reason] (
    [ID]         INT           IDENTITY (0, 1) NOT NULL,
    [company_id] INT           NOT NULL,
    [code]       NVARCHAR (10) NOT NULL,
    [addedTSUTC] DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[Return_Reason]
    ADD CONSTRAINT [PK__Return_Reason] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Return_Reason]
    ADD CONSTRAINT [DF__Return_Reason__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__921]
    ON [ext].[Return_Reason]([company_id] ASC, [code] ASC);
GO

ALTER TABLE [ext].[Return_Reason]
    ADD CONSTRAINT [FK__Return_Reason__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO
