CREATE TABLE [db_sys].[team_notification_log] (
    [ID]                        INT              IDENTITY (0, 1) NOT NULL,
    [auditLog_ID]               INT              NOT NULL,
    [ens_ID]                    INT              NOT NULL,
    [message_subject]           NVARCHAR (255)   NOT NULL,
    [message_body]              NVARCHAR (MAX)   NULL,
    [message_reply]             NVARCHAR (MAX)   NULL,
    [addTS]                     DATETIME2 (3)    NOT NULL,
    [postTS]                    DATETIME2 (3)    NULL,
    [place_holder]              UNIQUEIDENTIFIER NULL,
    [place_holder_session]      UNIQUEIDENTIFIER NULL,
    teams_message_id            BIGINT              NULL,
    teams_root_mid              BIGINT              NULL
);
GO

ALTER TABLE [db_sys].[team_notification_log]
    ADD CONSTRAINT [DF__team_notification_log__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__5AA]
    ON [db_sys].[team_notification_log]([place_holder] ASC) WHERE ([place_holder] IS NOT NULL);
GO

CREATE NONCLUSTERED INDEX IX__3ED
ON [db_sys].[team_notification_log] ([teams_root_mid])
GO

ALTER TABLE [db_sys].[team_notification_log]
    ADD CONSTRAINT [PK__team_notification_log_message] PRIMARY KEY CLUSTERED ([ID] ASC);
GO