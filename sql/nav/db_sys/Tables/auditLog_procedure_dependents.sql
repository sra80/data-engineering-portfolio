CREATE TABLE [db_sys].[auditLog_procedure_dependents] (
    [parent_auditLog_ID] INT NOT NULL,
    [auditLog_ID]        INT NOT NULL
);
GO

ALTER TABLE [db_sys].[auditLog_procedure_dependents]
    ADD CONSTRAINT [PK__auditLog_procedure_dependents] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC);
GO
