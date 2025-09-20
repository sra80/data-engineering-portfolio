CREATE TABLE [db_sys].[auditLog] (
    [ID]                    INT            IDENTITY (1, 1) NOT NULL,
    [eventBy]               NVARCHAR (128) NULL,
    [eventUTCStart]         DATETIME2 (1)  NULL,
    [eventUTCEnd]           DATETIME2 (1)  NULL,
    [eventType]             NVARCHAR (32)  NULL,
    [eventName]             NVARCHAR (128) NULL,
    [eventVersion]          NVARCHAR (16)  NULL,
    [eventDetail]           NVARCHAR (MAX) NULL,
    [place_holder]          uniqueidentifier null,
    [place_holder_session]  uniqueidentifier null,
    [is_active]             bit              not null
);
GO


create trigger [db_sys].[auditLog_delete] on [db_sys].[auditLog]
instead of delete
as
begin
	if @@ROWCOUNT > 0
	begin
	 raiserror ('Audit log rows cannot be deleted.',16,2)
	end
end
GO

ALTER TABLE [db_sys].[auditLog]
    ADD CONSTRAINT [DF__auditLog__eventUTCStart] DEFAULT (getutcdate()) FOR [eventUTCStart];
GO

ALTER TABLE [db_sys].[auditLog]
    ADD CONSTRAINT [DF__auditLog__eventBy] DEFAULT (lower(suser_sname())) FOR [eventBy];
GO

ALTER TABLE [db_sys].[auditLog]
    ADD CONSTRAINT [DF__auditLog__is_active] DEFAULT (1) FOR [is_active];
GO

ALTER TABLE [db_sys].[auditLog]
    ADD CONSTRAINT [PK__auditLog] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__auditLog__1]
    ON [db_sys].[auditLog]([eventName] ASC)
    INCLUDE([eventUTCEnd]);
GO

CREATE NONCLUSTERED INDEX [IX__auditLog__0]
    ON [db_sys].[auditLog]([eventName] ASC)
    INCLUDE([eventUTCEnd]);
GO

CREATE NONCLUSTERED INDEX IX__DBC
ON [db_sys].[auditLog] ([is_active],[place_holder])

CREATE NONCLUSTERED INDEX IX__7ED
ON [db_sys].[auditLog] ([eventUTCEnd])
GO

create index IX__E9C on db_sys.auditLog (is_active desc, ID desc)
go

create index IX__877 on db_sys.auditLog (place_holder_session)
go

create index IX__E7A on db_sys.auditLog (place_holder) where (place_holder is not null)
go

create or alter trigger [db_sys].[auditLog_update_insert] on [db_sys].[auditLog]

for update, insert

as

begin

set nocount on

    update
        a
    set
        a.is_active = case when i.eventUTCEnd is null then 1 else 0 end
    from
        db_sys.auditLog a
    join
        inserted i
    on
        (
            a.ID = i.ID
        )

    update
        a
    set
        a.eventUTCEnd = getutcdate(),
        a.eventDetail = 'Procedure Outcome: Failed'
    from
        db_sys.auditLog a
    join
        inserted i
    on
        (
            a.place_holder = i.place_holder
        )
    where
        (
            a.eventUTCEnd is null
        and a.ID != i.ID
        )


end