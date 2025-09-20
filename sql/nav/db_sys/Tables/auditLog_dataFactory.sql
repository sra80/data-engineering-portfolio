CREATE TABLE [db_sys].[auditLog_dataFactory] (
    [auditLog_ID] INT              NOT NULL,
    [run_ID]      UNIQUEIDENTIFIER NOT NULL
);
GO

ALTER TABLE [db_sys].[auditLog_dataFactory]
    ADD CONSTRAINT [PK__auditLog_dataFactory] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__8BC]
    ON [db_sys].[auditLog_dataFactory]([run_ID] ASC);
GO
