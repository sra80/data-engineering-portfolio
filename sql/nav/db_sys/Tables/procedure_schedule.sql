CREATE TABLE [db_sys].[procedure_schedule] (
    [ID]                   INT              NOT NULL    IDENTITY(0,1),
    [procedureName]        NVARCHAR (128)    NOT NULL,
    [schedule_disabled]    BIT              NOT NULL,
    [process]              BIT              NOT NULL,
    [process_active]       BIT              NOT NULL,
    [last_processed]       DATETIME         NULL,
    [next_due]             DATETIME2(0)     NULL,
    [frequency_unit]       NVARCHAR (16)    NULL,
    [frequency_value]      INT              NULL,
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
    [place_holder]         UNIQUEIDENTIFIER NULL,
    [error_count]          INT              NOT NULL,
    [overdue_from]         DATETIME2 (0)    NULL,
    [overdue_alert]        DATETIME2 (0)    NULL,
    [place_holder_session] UNIQUEIDENTIFIER NULL,
    [run_on_next_session]  bit not null
);
GO

ALTER TABLE [db_sys].[procedure_schedule]
    ADD CONSTRAINT [DF__process] DEFAULT ((0)) FOR [process];
GO

ALTER TABLE [db_sys].[procedure_schedule]
    ADD CONSTRAINT [DF__schedule_disabled] DEFAULT ((0)) FOR [schedule_disabled];
GO

ALTER TABLE [db_sys].[procedure_schedule]
    ADD CONSTRAINT [DF__process_active] DEFAULT ((0)) FOR [process_active];
GO

ALTER TABLE [db_sys].[procedure_schedule]
    ADD CONSTRAINT [DF__procedure_schedule__error_count] DEFAULT ((0)) FOR [error_count];
GO

ALTER TABLE [db_sys].[procedure_schedule]
    ADD CONSTRAINT [DF__procedure_schedule__run_on_next_session] DEFAULT ((0)) FOR [run_on_next_session];
GO


CREATE trigger [db_sys].[procedure_schedule__delete] on [db_sys].[procedure_schedule]

for delete

as

begin

set nocount on

update l set
    l.is_current = 0,
    l.deletedTSUTC = getutcdate(),
    l.deletedBy = lower(system_user)
from
    db_sys.procedure_schedule_changeLog l
join
    deleted d
on
    (
        l.procedureName = d.procedureName
    and l.is_current = 1
    )

end
GO

create or alter trigger [db_sys].[procedure_schedule__update] on [db_sys].[procedure_schedule]

for update, insert

as

begin

set nocount on

if system_user != 'process_model' and system_user != 'email_notifications' and system_user != 'job_credential' and db_sys.fn_user_is_uniqueidentifier(system_user) = 0

    begin

        update l set
            l.is_current = 0
        from
            db_sys.procedure_schedule_changeLog l
        join
            inserted i
        on
            (
                l.procedureName = i.procedureName
            and l.is_current = 1
            )

        insert into db_sys.procedure_schedule_changeLog (procedureName, schedule_disabled, frequency_unit, frequency_value, start_month, start_day, start_dow, start_hour, start_minute, end_month, end_day, end_dow, end_hour, end_minute, row_version, is_current, addedTSUTC, addedBy)
        select
            i.procedureName, 
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
            i.end_minute,
            isnull((select max(row_version) from db_sys.procedure_schedule_changeLog l where i.procedureName = l.procedureName) + 1,0),
            1,
            sysdatetime(),
            lower(system_user)
        from
            inserted i

    end

end
GO

ALTER TABLE [db_sys].[procedure_schedule]
    ADD CONSTRAINT [PK__procedure_schedule] PRIMARY KEY CLUSTERED ([ID] ASC);
GO --this refers to procedureName in the current version as ID was added later

CREATE UNIQUE INDEX IX__A42 ON [db_sys].[procedure_schedule] ([procedureName])
GO --this refers to ID in the current version as ID was added later

ALTER TABLE [db_sys].[procedure_schedule]
    ADD CONSTRAINT [FK__procedure_schedule__frequency_unit] FOREIGN KEY ([frequency_unit]) REFERENCES [db_sys].[schedule_frequency_unit] ([frequency_unit]);
GO