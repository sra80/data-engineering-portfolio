CREATE TABLE [db_sys].[MSreplication_objects_collision] (
    [ID]                 INT            IDENTITY (1, 1) NOT NULL,
    [article]            NVARCHAR (64)  NULL,
    [publications]       NVARCHAR (MAX) NOT NULL,
    [first_logged]       DATETIME2 (0)  NOT NULL,
    [first_notification] DATETIME2 (7)  NULL,
    [last_notification]  DATETIME2 (0)  NULL,
    [notification_count] INT            NOT NULL,
    [issue_notification] BIT            NOT NULL,
    [resolved]           DATETIME2 (0)  NULL
);
GO

ALTER TABLE [db_sys].[MSreplication_objects_collision]
    ADD CONSTRAINT [DF__MSreplication_objects_collision__issue_notification] DEFAULT ((0)) FOR [issue_notification];
GO

ALTER TABLE [db_sys].[MSreplication_objects_collision]
    ADD CONSTRAINT [DF__MSreplication_objects_collision__first_logged] DEFAULT (getutcdate()) FOR [first_logged];
GO

ALTER TABLE [db_sys].[MSreplication_objects_collision]
    ADD CONSTRAINT [DF__MSreplication_objects_collision__notification_count] DEFAULT ((0)) FOR [notification_count];
GO

ALTER TABLE [db_sys].[MSreplication_objects_collision]
    ADD CONSTRAINT [PK__MSreplication_objects_collision] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
