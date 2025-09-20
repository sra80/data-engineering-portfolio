CREATE TABLE [db_sys].[process_model_partitions] (
    [model_name]      NVARCHAR (32) NOT NULL,
    [table_name]      NVARCHAR (64) NOT NULL,
    [partition_name]  NVARCHAR (64) NOT NULL,
    [process]         BIT           NOT NULL,
    [last_processed]  DATETIME2(0)  NULL,
    [last_offset_ts]  DATETIME2(0) NULL,
    [next_due]        DATETIME2(0)  NULL,
    [frequency_unit]  NVARCHAR (16) NULL,
    [frequency_value] INT           NULL,
    [trigger_sp]      BIT           NOT NULL,
    [place_holder]    uniqueidentifier NULL
);
GO

ALTER TABLE [db_sys].[process_model_partitions]
    ADD CONSTRAINT [DF__process_model_partitions__trigger_sp] DEFAULT ((0)) FOR [trigger_sp];
GO

ALTER TABLE [db_sys].[process_model_partitions]
    ADD CONSTRAINT [DF__process_model_partitions__process] DEFAULT ((0)) FOR [process];
GO

CREATE trigger [db_sys].[process_model_partitions__delete] on [db_sys].[process_model_partitions]

for delete

as

begin

set nocount on

update l set
    l.is_current = 0,
    l.deletedTSUTC = getutcdate(),
    l.deletedBy = lower(system_user)
from
    db_sys.process_model_partitions_changeLog l
join
    deleted d
on
    (
        l.model_name = d.model_name
    and l.table_name = d.table_name
    and l.partition_name = d.partition_name
    and l.is_current = 1
    )

end
GO

create or alter trigger [db_sys].[process_model_partitions__update] on [db_sys].[process_model_partitions]

for update, insert

as

begin

set nocount on

if system_user != 'process_model' and system_user != 'email_notifications' and system_user != 'job_credential' and db_sys.fn_user_is_uniqueidentifier(system_user) = 0

    begin

        update l set
            l.is_current = 0
        from
            db_sys.process_model_partitions_changeLog l
        join
            inserted i
        on
            (
                l.model_name = i.model_name
            and l.table_name = i.table_name
            and l.partition_name = i.partition_name
            and l.is_current = 1
            )

        insert into db_sys.process_model_partitions_changeLog (model_name, table_name, partition_name, frequency_unit, frequency_value, row_version, is_current, addedTSUTC, addedBy)
        select
            i.model_name,
            i.table_name,
            i.partition_name,
            i.frequency_unit,
            i.frequency_value,
            isnull((select max(row_version) from db_sys.process_model_partitions_changeLog l where i.model_name = l.model_name and i.table_name = l.table_name and l.partition_name = i.partition_name) + 1,0),
            1,
            sysdatetime(),
            lower(system_user)
        from
            inserted i

    end

end
GO

ALTER TABLE [db_sys].[process_model_partitions]
    ADD CONSTRAINT [FK__process_model_partitions__frequency_unit] FOREIGN KEY ([frequency_unit]) REFERENCES [db_sys].[schedule_frequency_unit] ([frequency_unit]);
GO

ALTER TABLE [db_sys].[process_model_partitions]
    ADD CONSTRAINT [PK__process_model_partitions] PRIMARY KEY CLUSTERED ([model_name] ASC, [table_name] ASC, [partition_name] ASC);
GO
