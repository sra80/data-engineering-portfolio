CREATE TABLE [db_sys].[auditLog_logicApp_identifier_local] (
    [ID]         NVARCHAR (36)    NOT NULL,
    [sessionID]  UNIQUEIDENTIFIER NOT NULL,
    [addedTSUTC] DATETIME2 (1)    NULL
);
GO

ALTER TABLE [db_sys].[auditLog_logicApp_identifier_local]
    ADD CONSTRAINT [PK__auditLog_logicApp_identifier] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__auditLog_logicApp_identifier__sessionID]
    ON [db_sys].[auditLog_logicApp_identifier_local]([sessionID] ASC);
GO

ALTER TABLE [db_sys].[auditLog_logicApp_identifier_local]
    ADD CONSTRAINT [DF__auditLog_logicApp_identifier__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO
