CREATE TABLE [ext].[VAT_Posting_Setup] (
    [ID]                 INT           IDENTITY (0, 1) NOT NULL,
    [company_id]         INT           NOT NULL,
    [Bus_Posting_Group]  NVARCHAR (10) NOT NULL,
    [Prod_Posting_Group] NVARCHAR (10) NOT NULL,
    [addTSUTC]           DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[VAT_Posting_Setup]
    ADD CONSTRAINT [PK__VAT_Posting_Setup] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[VAT_Posting_Setup]
    ADD CONSTRAINT [FK__VAT_Posting_Setup__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[VAT_Posting_Setup]
    ADD CONSTRAINT [DF__VAT_Posting_Setup__addTSUTC] DEFAULT (sysdatetime()) FOR [addTSUTC];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__BDD]
    ON [ext].[VAT_Posting_Setup]([company_id] ASC, [Bus_Posting_Group] ASC, [Prod_Posting_Group] ASC);
GO
