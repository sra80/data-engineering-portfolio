CREATE TABLE [db_sys].[team_notification_setup] (
    [ens_ID] INT NOT NULL,
    [tnc_ID] INT NOT NULL,
    [is_reply_on_same] BIT NOT NULL,
    [bodySource_hashbytes] varbinary(32) null,
    [reply_place_holder] uniqueidentifier null
);
GO

ALTER TABLE [db_sys].[team_notification_setup]
    ADD CONSTRAINT [PK__team_notification_setup] PRIMARY KEY CLUSTERED ([ens_ID] ASC, [tnc_ID] ASC);
GO

alter table [db_sys].[team_notification_setup] add constraint DF__team_notification_setup__is_reply_on_same default 0 for is_reply_on_same
go

create or alter trigger [db_sys].[tr_team_notification_setup] on [db_sys].[team_notification_setup]

for update, delete, insert

as

begin

set nocount on

if system_user != 'process_model' and system_user != 'email_notifications' and system_user != 'job_credential' and db_sys.fn_user_is_uniqueidentifier(system_user) = 0

    begin

        update l set
            l.is_current = 0,
            deletedTSUTC = sysdatetime(),
            deletedBy = lower(system_user)
        from
            db_sys.team_notification_setup_changeLog l
        join
            deleted d
        on
            (
                l.ens_ID = d.ens_ID
            and l.tnc_ID = d.tnc_ID
            and l.is_current = 1
            )


        update l set
            l.is_current = 0
        from
            db_sys.team_notification_setup_changeLog l
        join
            inserted i
        on
            (
                l.ens_ID = i.ens_ID
            and l.tnc_ID = i.tnc_ID
            and l.is_current = 1
            )

        insert into db_sys.team_notification_setup_changeLog (ens_ID, tnc_ID, is_reply_on_same, row_version, is_current, addedTSUTC, addedBy)
        select
            i.ens_ID,
            i.tnc_ID,
            i.is_reply_on_same,
            isnull((select max(row_version) from db_sys.team_notification_setup_changeLog l where l.ens_ID = i.ens_ID and l.tnc_ID = i.tnc_ID) + 1,0),
            1,
            sysdatetime(),
            lower(system_user)
        from
            inserted i

    end

end
GO