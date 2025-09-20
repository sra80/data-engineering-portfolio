CREATE TABLE [db_sys].[procedure_schedule_pairing] (
    [procedureName_parent] NVARCHAR (128) NOT NULL,
    [procedureName_child]  NVARCHAR (128) NOT NULL,
    [addTS]                DATETIME2 (3) NULL
);
GO

ALTER TABLE [db_sys].[procedure_schedule_pairing]
    ADD CONSTRAINT [DF__procedure_schedule_pairing__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [db_sys].[procedure_schedule_pairing]
    ADD CONSTRAINT [FK__procedure_schedule_pairing__procedureName_child] FOREIGN KEY ([procedureName_child]) REFERENCES [db_sys].[procedure_schedule] ([procedureName]);
GO

ALTER TABLE [db_sys].[procedure_schedule_pairing]
    ADD CONSTRAINT [FK__procedure_schedule_pairing__procedureName_parent] FOREIGN KEY ([procedureName_parent]) REFERENCES [db_sys].[procedure_schedule] ([procedureName]);
GO

ALTER TABLE [db_sys].[procedure_schedule_pairing]
    ADD CONSTRAINT [PK__procedure_schedule_pairing] PRIMARY KEY CLUSTERED ([procedureName_parent] ASC, [procedureName_child] ASC);
GO