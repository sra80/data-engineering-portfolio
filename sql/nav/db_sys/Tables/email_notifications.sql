CREATE TABLE [db_sys].[email_notifications] (
    [ID]                              INT            IDENTITY (1, 1) NOT NULL,
    [email_to]                        NVARCHAR (MAX) NULL,
    [email_cc]                        NVARCHAR (MAX) NULL,
    [email_subject]                   NVARCHAR (255) NULL,
    [email_body]                      NVARCHAR (MAX) NOT NULL,
    [email_importance]                NVARCHAR (8)   NOT NULL,
    [email_notifications_schedule_ID] INT            NULL,
    [requestedUTC]                    DATETIME2 (1)  NOT NULL,
    [requestBy]                       NVARCHAR (255)  NOT NULL,
    [email_sent]                      DATETIME2 (1)  NULL,
    [auditLog_ID]                     INT            NULL, --if >-2 (see [db_sys].[vw_email_notifications], email will send, so to prevent an e-mail being issued, set to -2 or lower)
    [place_holder]                    uniqueidentifier null
);
GO

ALTER TABLE [db_sys].[email_notifications]
    ADD CONSTRAINT [DF__email_notifications__email_importance] DEFAULT ('Normal') FOR [email_importance];
GO

ALTER TABLE [db_sys].[email_notifications]
    ADD CONSTRAINT [DF__email_notifications__requestedUTC] DEFAULT (getutcdate()) FOR [requestedUTC];
GO

ALTER TABLE [db_sys].[email_notifications]
    ADD CONSTRAINT [DF__email_notifications__requestBy] DEFAULT (lower(suser_sname())) FOR [requestBy];
GO

ALTER TABLE [db_sys].[email_notifications]
    ADD CONSTRAINT [PK__email_notifications] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

create index IX__F3A on [db_sys].[email_notifications] (place_holder) where (place_holder is not null)
go