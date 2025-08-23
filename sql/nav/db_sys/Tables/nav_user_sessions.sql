CREATE TABLE [db_sys].[nav_user_sessions] (
    [auditLog_ID]  INT           NOT NULL,
    [UserID]       NVARCHAR (64) NOT NULL,
    [sessionCount] INT           NOT NULL,
    [addedTSUTC]   DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [db_sys].[nav_user_sessions]
    ADD CONSTRAINT [DF__nav_user_sessions__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [db_sys].[nav_user_sessions]
    ADD CONSTRAINT [PK__nav_user_sessions] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC, [UserID] ASC);
GO
