CREATE TABLE [db_sys].[auditLog_sessions] (
    [ID]          UNIQUEIDENTIFIER NOT NULL,
    [auditLog_ID] INT              NOT NULL
);
GO

ALTER TABLE [db_sys].[auditLog_sessions]
    ADD CONSTRAINT [PK__auditLog_sessions] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__B23]
    ON [db_sys].[auditLog_sessions]([ID] ASC);
GO
