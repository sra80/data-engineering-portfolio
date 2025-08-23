CREATE TABLE [ext].[Sales_Delete] (
    [Document Type] INT           NOT NULL,
    [No_]           NVARCHAR (20) NOT NULL,
    [auditLog_ID]   INT           NOT NULL,
    [company_id]    INT           NOT NULL
);
GO

ALTER TABLE [ext].[Sales_Delete]
    ADD CONSTRAINT [FK__Sales_Delete__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Sales_Delete]
    ADD CONSTRAINT [PK__Sales_Delete] PRIMARY KEY CLUSTERED ([company_id] ASC, [Document Type] ASC, [No_] ASC);
GO
