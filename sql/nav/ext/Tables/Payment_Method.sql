CREATE TABLE [ext].[Payment_Method] (
    [ID]         INT           IDENTITY (0, 1) NOT NULL,
    [company_id] INT           NOT NULL,
    [pm_code]    NVARCHAR (10) NOT NULL,
    [addedTSUTC] DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[Payment_Method]
    ADD CONSTRAINT [FK__Payment_Method__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Payment_Method]
    ADD CONSTRAINT [DF__Payment_Method__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__5C3]
    ON [ext].[Payment_Method]([company_id] ASC, [pm_code] ASC);
GO

ALTER TABLE [ext].[Payment_Method]
    ADD CONSTRAINT [PK__Payment_Method] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
