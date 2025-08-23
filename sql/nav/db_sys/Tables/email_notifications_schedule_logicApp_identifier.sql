CREATE TABLE [db_sys].[email_notifications_schedule_logicApp_identifier] (
    [logicApp_ID] NVARCHAR (36) NOT NULL,
    [auditLog_ID] INT           NOT NULL,
    [addedTSUTC]  DATETIME2 (1) NOT NULL,
    [ens_ID]      INT           NOT NULL
);
GO

ALTER TABLE [db_sys].[email_notifications_schedule_logicApp_identifier]
    ADD CONSTRAINT [DF__email_notifications_schedule_logicApp_identifier__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [db_sys].[email_notifications_schedule_logicApp_identifier]
    ADD CONSTRAINT [PK__email_notifications_schedule_logicApp_identifier] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC);
GO
