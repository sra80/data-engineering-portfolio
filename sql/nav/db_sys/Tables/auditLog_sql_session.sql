CREATE TABLE [db_sys].[auditLog_sql_session] (
    [session_id]   INT              NOT NULL,
    [place_holder] UNIQUEIDENTIFIER NOT NULL,
    [tsUTC]        DATETIME2 (3)    NOT NULL
);
GO

ALTER TABLE [db_sys].[auditLog_sql_session]
    ADD CONSTRAINT [DF__auditLog_sql_session__tsUTC] DEFAULT (sysdatetime()) FOR [tsUTC];
GO
