CREATE TABLE [finance].[SalesInvoices_auditLog] (
    [auditLog_ID]  INT            NOT NULL,
    [step]         INT            NOT NULL,
    [command]      NVARCHAR (MAX) NOT NULL,
    [stepUTCStart] DATETIME2 (1)  NULL,
    [stepUTCEnd]   DATETIME2 (1)  NULL
);
GO

ALTER TABLE [finance].[SalesInvoices_auditLog]
    ADD CONSTRAINT [PK__SalesInvoices_auditLog] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC, [step] ASC);
GO
