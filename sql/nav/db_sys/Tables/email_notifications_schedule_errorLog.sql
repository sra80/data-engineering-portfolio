CREATE TABLE [db_sys].[email_notifications_schedule_errorLog] (
    [ID]             INT            IDENTITY (0, 1) NOT NULL,
    [schedule_ID]    INT            NOT NULL,
    [auditLog_ID]    INT            NOT NULL,
    [error_message]  NVARCHAR (MAX) NULL,
    [dateAddedTSUTC] DATETIME2 (1)  NOT NULL
);
GO

ALTER TABLE [db_sys].[email_notifications_schedule_errorLog]
    ADD CONSTRAINT [DF__email_notifications_schedule_errorLog__dateAddedTSUTC] DEFAULT (getutcdate()) FOR [dateAddedTSUTC];
GO

ALTER TABLE [db_sys].[email_notifications_schedule_errorLog]
    ADD CONSTRAINT [PK__email_notifications_schedule_errorLog] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
