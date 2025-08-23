CREATE TABLE [db_sys].[team_notification_log2] (
    [en_ID]    INT           NOT NULL,
    [tnc_ID]   INT           NOT NULL,
    [postedTS] DATETIME2 (3) NULL
);
GO

ALTER TABLE [db_sys].[team_notification_log2]
    ADD CONSTRAINT [PK__team_notification_log] PRIMARY KEY CLUSTERED ([en_ID] ASC, [tnc_ID] ASC);
GO
