CREATE TABLE [db_sys].[email_notifications_schedule_changeLog] (
    [schedule_ID]       INT            NOT NULL,
    [row_version]       INT            NOT NULL,
    [is_current]        BIT            NOT NULL,
    [email_trigger]     NVARCHAR (MAX) NULL,
    [email_to]          NVARCHAR (MAX) NULL,
    [email_cc]          NVARCHAR (MAX) NULL,
    [email_subject]     NVARCHAR (255) NOT NULL,
    [email_bodyIntro]   NVARCHAR (MAX) NULL,
    [email_bodySource]  NVARCHAR (64)  NULL,
    [email_bodyOutro]   NVARCHAR (MAX) NULL,
    [email_importance]  NVARCHAR (8)   NULL,
    [schedule_disabled] BIT            NOT NULL,
    [frequency_unit]    NVARCHAR (16)  NOT NULL,
    [frequency_value]   INT            NOT NULL,
    [start_month]       INT            NULL,
    [start_day]         INT            NULL,
    [start_dow]         INT            NULL,
    [start_hour]        INT            NULL,
    [start_minute]      INT            NULL,
    [end_month]         INT            NULL,
    [end_day]           INT            NULL,
    [end_dow]           INT            NULL,
    [end_hour]          INT            NULL,
    [end_minute]        INT            NULL,
    [addedTSUTC]        DATETIME2 (1)  NULL,
    [addedBy]           NVARCHAR (128) NOT NULL,
    [deletedTSUTC]      DATETIME2 (1)  NULL,
    [deletedBy]         NVARCHAR (128) NULL
);
GO

ALTER TABLE [db_sys].[email_notifications_schedule_changeLog]
    ADD CONSTRAINT [DF__email_notifications_schedule_changeLog__addedBy] DEFAULT (lower(suser_sname())) FOR [addedBy];
GO

ALTER TABLE [db_sys].[email_notifications_schedule_changeLog]
    ADD CONSTRAINT [DF__email_notifications_schedule_changeLog__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [db_sys].[email_notifications_schedule_changeLog]
    ADD CONSTRAINT [PK__email_notifications_schedule_changeLog] PRIMARY KEY CLUSTERED ([schedule_ID] ASC, [row_version] ASC);
GO
