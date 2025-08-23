CREATE TABLE [db_sys].[process_model] (
    [model_name]      NVARCHAR (32) NOT NULL,
    [process_active]  BIT           NOT NULL,
    [disable_process] BIT           NOT NULL,
    [model_url]       AS            (('https://westeurope.asazure.windows.net/servers/hsbianalysisservices/models/'+lower([model_name]))+'/refreshes'),
    [start_month]     INT           NULL,
    [start_day]       INT           NULL,
    [start_dow]       INT           NULL,
    [start_hour]      INT           NULL,
    [start_minute]    INT           NULL,
    [end_month]       INT           NULL,
    [end_day]         INT           NULL,
    [end_dow]         INT           NULL,
    [end_hour]        INT           NULL,
    [end_minute]      INT           NULL,
    [place_holder]    uniqueidentifier NULL,
    [error_count]     INT           NOT NULL,
    [overdue_from]    DATETIME2 (0) NULL,
    [overdue_alert]   DATETIME2 (0) NULL,
    [MaxParallelism]  INT           NOT NULL
);
GO

CREATE trigger [db_sys].[process_model__delete] on [db_sys].[process_model]

for delete

as

begin

set nocount on

update l set
    l.is_current = 0,
    l.deletedTSUTC = getutcdate(),
    l.deletedBy = lower(system_user)
from
    db_sys.process_model_changeLog l
join
    deleted d
on
    (
        l.model_name = d.model_name
    and l.is_current = 1
    )

end
GO

CREATE or alter trigger [db_sys].[process_model__update] on [db_sys].[process_model]

for update, insert

as

begin

set nocount on

if system_user != 'process_model' and system_user != 'email_notifications' and system_user != 'job_credential' and db_sys.fn_user_is_uniqueidentifier(system_user) = 0

    begin

        update l set
            l.is_current = 0
        from
            db_sys.process_model_changeLog l
        join
            inserted i
        on
            (
                l.model_name = i.model_name
            and l.is_current = 1
            )

        insert into db_sys.process_model_changeLog (model_name, disable_process, start_month, start_day, start_dow, start_hour, start_minute, end_month, end_day, end_dow, end_hour, end_minute, row_version, is_current, addedTSUTC, addedBy)
        select
            i.model_name,
            i.disable_process,
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
            isnull((select max(row_version) from db_sys.process_model_changeLog l where i.model_name = l.model_name) + 1,0),
            1,
            sysdatetime(),
            lower(system_user)
        from
            inserted i

    end

end
GO

ALTER TABLE [db_sys].[process_model]
    ADD CONSTRAINT [PK__process_model] PRIMARY KEY CLUSTERED ([model_name] ASC);
GO

ALTER TABLE [db_sys].[process_model]
    ADD CONSTRAINT [CK__process_model__MaxParallelism] CHECK ([MaxParallelism]>(0) AND [MaxParallelism]<(4));
GO

ALTER TABLE [db_sys].[process_model]
    ADD CONSTRAINT [DF__process_model__MaxParallelism] DEFAULT ((2)) FOR [MaxParallelism];
GO

ALTER TABLE [db_sys].[process_model]
    ADD CONSTRAINT [DF__process_model__error_count] DEFAULT ((0)) FOR [error_count];
GO

ALTER TABLE [db_sys].[process_model]
    ADD CONSTRAINT [DF__process_model__disable_process] DEFAULT ((0)) FOR [disable_process];
GO

ALTER TABLE [db_sys].[process_model]
    ADD CONSTRAINT [DF__process_model__process_active] DEFAULT ((0)) FOR [process_active];
GO