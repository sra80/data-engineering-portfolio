CREATE TABLE [db_sys].[auditLog_logicApp_identifier_model] (
    [auditLog_ID] INT           NOT NULL,
    [ID]          NVARCHAR (36) NOT NULL,
    [addedTSUTC]  DATETIME2 (1) NOT NULL
);
GO

ALTER TABLE [db_sys].[auditLog_logicApp_identifier_model]
    ADD CONSTRAINT [PK__auditLog_logicApp_identifier_model] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC);
GO

ALTER TABLE [db_sys].[auditLog_logicApp_identifier_model]
    ADD CONSTRAINT [DF__auditLog_logicApp_identifier_model__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO
