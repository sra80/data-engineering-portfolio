CREATE TABLE [db_sys].[timestamp_tracker] (
    [stored_procedure] NVARCHAR (64)  NOT NULL,
    [table_name]       NVARCHAR (128) NOT NULL,
    [last_timestamp]   VARBINARY (8)  NOT NULL,
    [last_update]      DATETIME2 (7)  NULL
);
GO

ALTER TABLE [db_sys].[timestamp_tracker]
    ADD CONSTRAINT [DF__timestamp_tracker__last_timestamp] DEFAULT ((0)) FOR [last_timestamp];
GO

ALTER TABLE [db_sys].[timestamp_tracker]
    ADD CONSTRAINT [PK__timestamp_tracker] PRIMARY KEY CLUSTERED ([stored_procedure] ASC, [table_name] ASC);
GO
