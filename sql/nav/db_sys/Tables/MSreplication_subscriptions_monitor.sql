CREATE TABLE [db_sys].[MSreplication_subscriptions_monitor] (
    [publisher]                     NVARCHAR (64)  NOT NULL,
    [publisher_db]                  NVARCHAR (64)  NOT NULL,
    [publication]                   NVARCHAR (64)  NOT NULL,
    [transaction_timestamp]         VARBINARY (16) NOT NULL,
    [transaction_timestamp_arrival] DATETIME2 (0)  NOT NULL,
    [last_notification]             DATETIME2 (0)  NULL,
    [issue_notification]            BIT            NOT NULL,
    [notification_count]            INT            NOT NULL,
    [issue_count]                   INT            NOT NULL,
    [resolved_notification]         BIT            NOT NULL,
    [is_outofsync]                  BIT            NOT NULL
);
GO

ALTER TABLE [db_sys].[MSreplication_subscriptions_monitor]
    ADD CONSTRAINT [DF__MSreplication_subscriptions_monitor__resolved_notification] DEFAULT ((0)) FOR [resolved_notification];
GO

ALTER TABLE [db_sys].[MSreplication_subscriptions_monitor]
    ADD CONSTRAINT [DF__MSreplication_subscriptions_monitor__is_outofsync] DEFAULT ((0)) FOR [is_outofsync];
GO

ALTER TABLE [db_sys].[MSreplication_subscriptions_monitor]
    ADD CONSTRAINT [PK__MSreplication_subscriptions_monitor] PRIMARY KEY CLUSTERED ([publisher] ASC, [publisher_db] ASC, [publication] ASC);
GO
