CREATE TABLE [db_sys].[email_notifications_recipients] (
    [tag]           NVARCHAR (32)  NOT NULL,
    [email_address] NVARCHAR (255) NOT NULL,
    [to_cc]         NVARCHAR (2)   NOT NULL,
    [is_inactive]   BIT            NOT NULL
);
GO

ALTER TABLE [db_sys].[email_notifications_recipients]
    ADD CONSTRAINT [DF__email_notifications_recipients__is_inactive] DEFAULT ((0)) FOR [is_inactive];
GO

ALTER TABLE [db_sys].[email_notifications_recipients]
    ADD CONSTRAINT [DF__email_notifications_recipients__to_cc] DEFAULT ('to') FOR [to_cc];
GO

ALTER TABLE [db_sys].[email_notifications_recipients]
    ADD CONSTRAINT [PK__email_notifications_recipients] PRIMARY KEY CLUSTERED ([tag] ASC, [email_address] ASC);
GO
