CREATE TABLE [db_sys].[auditLog_jams] (
    [auditLog_ID] INT           NOT NULL,
    [addedTSUTC]  DATETIME2 (0) NULL
);
GO

ALTER TABLE [db_sys].[auditLog_jams]
    ADD CONSTRAINT [PK__auditLog_job_stuck] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC);
GO

ALTER TABLE [db_sys].[auditLog_jams]
    ADD CONSTRAINT [DF__auditLog_jams__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO
