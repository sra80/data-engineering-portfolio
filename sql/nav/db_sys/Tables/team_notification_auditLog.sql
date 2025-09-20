CREATE TABLE [db_sys].[team_notification_auditLog] (
    [tnl_ID] INT           NOT NULL,
    [tnc_ID] INT           NOT NULL,
    [postTS] DATETIME2 (3) NULL
);
GO

ALTER TABLE [db_sys].[team_notification_auditLog]
    ADD CONSTRAINT [PK__team_notification_auditLog] PRIMARY KEY CLUSTERED ([tnl_ID] ASC, [tnc_ID] ASC);
GO
