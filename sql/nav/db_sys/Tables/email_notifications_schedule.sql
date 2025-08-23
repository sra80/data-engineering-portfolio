CREATE TABLE [db_sys].[email_notifications_schedule] (
    [ID]                   INT              IDENTITY (1, 1) NOT NULL,
    [email_trigger]        NVARCHAR (MAX)   NULL,
    [email_to]             NVARCHAR (MAX)   NULL,
    [email_cc]             NVARCHAR (MAX)   NULL,
    [email_subject]        NVARCHAR (255)   NOT NULL,
    [email_bodyIntro]      NVARCHAR (MAX)   NULL,
    [email_bodySource]     NVARCHAR (64)    NULL,
    [email_bodyOutro]      NVARCHAR (MAX)   NULL,
    [email_importance]     NVARCHAR (8)     NULL,
    [schedule_disabled]    BIT              NOT NULL,
    [last_processed]       DATETIME         NULL,
    [frequency_unit]       NVARCHAR (16)    NOT NULL,
    [frequency_value]      INT              NOT NULL,
    [start_month]          INT              NULL,
    [start_day]            INT              NULL,
    [start_dow]            INT              NULL,
    [start_hour]           INT              NULL,
    [start_minute]         INT              NULL,
    [end_month]            INT              NULL,
    [end_day]              INT              NULL,
    [end_dow]              INT              NULL,
    [end_hour]             INT              NULL,
    [end_minute]           INT              NULL,
    [error_count]          INT              NOT NULL,
    [is_processing]        BIT              NOT NULL,
    [place_holder]         UNIQUEIDENTIFIER NULL,
    [place_holder_session] UNIQUEIDENTIFIER NULL,
    [is_queued]            BIT              NOT NULL,
    [greeting]             BIT              NOT NULL,
    [is_dg]                BIT              NOT NULL,
    [reply_to_previous]    INT              NOT NULL,
    [reply_place_holder]   UNIQUEIDENTIFIER NULL 
);
GO

CREATE or ALTER trigger [db_sys].[email_notifications_schedule__delete] on [db_sys].[email_notifications_schedule]

for delete

as

begin

set nocount on

update db_sys.email_notifications_schedule_changeLog set is_current = 0, deletedTSUTC = getutcdate(), deletedBy = lower(system_user) where schedule_ID in (select ID from deleted) and is_current = 1

end
GO

create or alter trigger [db_sys].[email_notifications_schedule__update] on [db_sys].[email_notifications_schedule]

for update, insert

as

begin

set nocount on

if system_user != 'email_notifications' and system_user != '08131045-1014-4228-a8be-18d0867034cc@fe86a582-3a6a-4dbe-b1d0-8450f5ab1781'

    begin

        update db_sys.email_notifications_schedule_changeLog set is_current = 0 where schedule_ID in (select ID from inserted) and is_current = 1

        insert into db_sys.email_notifications_schedule_changeLog (schedule_ID,row_version,is_current,email_trigger,email_to,email_cc,email_subject,email_bodyIntro,email_bodySource,email_bodyOutro,email_importance,schedule_disabled,frequency_unit,frequency_value,start_month,start_day,start_dow,start_hour,start_minute,end_month,end_day,end_dow,end_hour,end_minute)
        select
            i.ID,
            (select isnull(max(row_version),-1) from db_sys.email_notifications_schedule_changeLog ensc where ensc.schedule_ID = i.ID) + 1,
            1,
            i.email_trigger,
            i.email_to,
            i.email_cc,
            i.email_subject,
            i.email_bodyIntro,
            i.email_bodySource,
            i.email_bodyOutro,
            i.email_importance,
            i.schedule_disabled,
            i.frequency_unit,
            i.frequency_value,
            i.start_month,
            i.start_day,
            i.start_dow,
            i.start_hour,
            i.start_minute,
            i.end_month,
            i.end_day,
            i.end_dow,
            i.end_hour,
            i.end_minute
        from
            inserted i

    end

end
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [PK__email_notifications_schedule] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [DF__email_notifications_schedule__is_dg] DEFAULT ((0)) FOR [is_dg];
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [DF__email_notifications_schedule__is_processing] DEFAULT ((0)) FOR [is_processing];
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [DF__email_notifications_schedule__greeting] DEFAULT ((0)) FOR [greeting];
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [DF__email_notifications_schedule__error_count] DEFAULT ((0)) FOR [error_count];
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [DF__email_notifications_schedule__is_queued] DEFAULT ((0)) FOR [is_queued];
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [DF__email_notifications_schedule__schedule_disabled] DEFAULT ((0)) FOR [schedule_disabled];
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [FK__email_notifications_schedule__frequency_unit] FOREIGN KEY ([frequency_unit]) REFERENCES [db_sys].[schedule_frequency_unit] ([frequency_unit]);
GO

ALTER TABLE [db_sys].[email_notifications_schedule]
    ADD CONSTRAINT [DF__email_notifications_schedule__reply_to_previous] DEFAULT ((0)) FOR [reply_to_previous];
GO