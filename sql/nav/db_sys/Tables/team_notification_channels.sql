CREATE TABLE [db_sys].[team_notification_channels] (
    [ID]           INT            IDENTITY (0, 1) NOT NULL,
    [channel_id]   NVARCHAR (256) NOT NULL,
    [channel_name] NVARCHAR (128) NOT NULL,
    [webUrl]       NVARCHAR (1024) NULL,
    [insertTS]     DATETIME2 (3)  NOT NULL,
    [updateTS]     DATETIME2 (3)  NULL,
    [deleteTS]     DATETIME2 (3)  NULL
);
GO

GRANT INSERT
    ON OBJECT::[db_sys].[team_notification_channels] TO [hs-bi-datawarehouse-la-aad-teams]
    AS [dbo];
GO

GRANT UPDATE
    ON OBJECT::[db_sys].[team_notification_channels] TO [hs-bi-datawarehouse-la-aad-teams]
    AS [dbo];
GO

ALTER TABLE [db_sys].[team_notification_channels]
    ADD CONSTRAINT [DF__team_notification_channels__insertTS] DEFAULT (sysdatetime()) FOR [insertTS];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__500]
    ON [db_sys].[team_notification_channels]([channel_id] ASC);
GO

ALTER TABLE [db_sys].[team_notification_channels]
    ADD CONSTRAINT [PK__team_notification_channels] PRIMARY KEY CLUSTERED ([ID] ASC);
GO