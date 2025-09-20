CREATE TABLE [db_sys].[Users] (
    [ID]             INT              IDENTITY (0, 1) NOT NULL,
    [ad_id]          NVARCHAR (64)    NOT NULL,
    [firstname]      NVARCHAR (32)    NULL,
    [surname]        NVARCHAR (32)    NULL,
    [addTS]          DATETIME2 (3)    NOT NULL,
    [email]          NVARCHAR (255)   NULL,
    [mitel_user_key] UNIQUEIDENTIFIER NULL,
    [mitel_team_key] UNIQUEIDENTIFIER NULL
);
GO

ALTER TABLE [db_sys].[Users]
    ADD CONSTRAINT [FK__Users__mitel_team_key] FOREIGN KEY ([mitel_team_key]) REFERENCES [mitel].[agent_group] ([id]);
GO

ALTER TABLE [db_sys].[Users]
    ADD CONSTRAINT [FK__Users__mitel_user_key] FOREIGN KEY ([mitel_user_key]) REFERENCES [mitel].[agent_list] ([id]);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__673]
    ON [db_sys].[Users]([mitel_user_key] ASC) WHERE ([mitel_user_key] IS NOT NULL);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__EEE]
    ON [db_sys].[Users]([ad_id] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__F9B]
    ON [db_sys].[Users]([email] ASC) WHERE ([email] IS NOT NULL);
GO


CREATE trigger [db_sys].[TR__Users__delete] on [db_sys].[Users]

for delete

as

begin

set nocount on

update l set
    l.is_current = 0,
    l.delTS = sysdatetime(),
    l.delBy = lower(system_user)
from
    db_sys.Users_changeLog l
join
    deleted d
on
    (
        l.ID = d.ID
    and l.is_current = 1
    )

end
GO

CREATE trigger [db_sys].[TR__Users__update] on [db_sys].[Users]

for update, insert

as

begin

set nocount on

    begin

        update l set
            l.is_current = 0
        from
            db_sys.Users_changeLog l
        join
            inserted i
        on
            (
                l.ID = i.ID
            and l.is_current = 1
            )

        insert into db_sys.Users_changeLog
            (
                ID,
                ad_id,
                firstname,
                surname,
                addTS,
                email,
                mitel_user_key,
                mitel_team_key,
                row_version,
                is_current,
                addBy
            )
        select
            i.ID,
            i.ad_id,
            i.firstname,
            i.surname,
            case when (select max(row_version) from db_sys.Users_changeLog l where i.ID = l.ID) is null then i.addTS else sysdatetime() end,
            i.email,
            i.mitel_user_key,
            i.mitel_team_key,
            isnull((select max(row_version) from db_sys.Users_changeLog l where i.ID = l.ID) + 1,0),
            1,
            lower(system_user)
        from
            inserted i

    end

end
GO

ALTER TABLE [db_sys].[Users]
    ADD CONSTRAINT [PK__Users] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [db_sys].[Users]
    ADD CONSTRAINT [DF__Users__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO
