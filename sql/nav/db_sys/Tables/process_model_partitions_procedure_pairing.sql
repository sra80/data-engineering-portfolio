
CREATE TABLE [db_sys].[process_model_partitions_procedure_pairing] (
    [model_name]     NVARCHAR (32) NOT NULL,
    [table_name]     NVARCHAR (64) NOT NULL,
    [partition_name] NVARCHAR (64) NOT NULL,
    [procedureName]  NVARCHAR (128) NOT NULL
);
GO

ALTER TABLE [db_sys].[process_model_partitions_procedure_pairing]
    ADD CONSTRAINT [PK__process_model_partitions_procedure_pairing] PRIMARY KEY CLUSTERED ([model_name] ASC, [table_name] ASC, [partition_name] ASC, [procedureName] ASC);
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

CREATE trigger [db_sys].[process_model_partitions_procedure_pairing__update] on [db_sys].[process_model_partitions_procedure_pairing]

for update, insert

as

begin

set nocount on

if system_user != 'process_model' and system_user != 'email_notifications' and system_user != 'job_credential'

    begin

        update l set
            l.is_current = 0
        from
            db_sys.process_model_partitions_procedure_pairing_changeLog l
        join
            inserted i
        on
            (
                l.model_name = i.model_name
            and l.table_name = i.table_name
            and l.partition_name = i.partition_name
            and l.procedureName = i.procedureName
            and l.is_current = 1
            )

        insert into db_sys.process_model_partitions_procedure_pairing_changeLog (model_name, table_name, partition_name, procedureName, row_version, is_current, addedTSUTC, addedBy)
        select
            i.model_name,
            i.table_name,
            i.partition_name,
            i.procedureName,
            isnull((select max(row_version) from db_sys.process_model_partitions_procedure_pairing_changeLog l where i.model_name = l.model_name and i.table_name = l.table_name and l.partition_name = i.partition_name and l.procedureName = i.procedureName) + 1,0),
            1,
            sysdatetime(),
            lower(system_user)
        from
            db_sys.process_model_partitions_procedure_pairing i

    end

end
GO

CREATE trigger [db_sys].[process_model_partitions_procedure_pairing__delete] on [db_sys].[process_model_partitions_procedure_pairing]

for delete

as

begin

set nocount on

update l set
    l.is_current = 0,
    l.deletedTSUTC = getutcdate(),
    l.deletedBy = lower(system_user)
from
    db_sys.process_model_partitions_procedure_pairing_changeLog l
join
    deleted d
on
    (
        l.model_name = d.model_name
    and l.table_name = d.table_name
    and l.partition_name = d.partition_name
    and l.procedureName = d.procedureName
    and l.is_current = 1
    )

end
GO
