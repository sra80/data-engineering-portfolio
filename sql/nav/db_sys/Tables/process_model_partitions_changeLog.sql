CREATE TABLE [db_sys].[process_model_partitions_changeLog] (
    [model_name]      NVARCHAR (32)  NOT NULL,
    [table_name]      NVARCHAR (64)  NOT NULL,
    [partition_name]  NVARCHAR (64)  NOT NULL,
    [frequency_unit]  NVARCHAR (16)  NULL,
    [frequency_value] INT            NULL,
    [row_version]     INT            NOT NULL,
    [is_current]      BIT            NOT NULL,
    [addedTSUTC]      DATETIME2 (1)  NOT NULL,
    [addedBy]         NVARCHAR (128) NOT NULL,
    [deletedTSUTC]    DATETIME2 (1)  NULL,
    [deletedBy]       NVARCHAR (128) NULL
);
GO

ALTER TABLE [db_sys].[process_model_partitions_changeLog]
    ADD CONSTRAINT [PK__process_model_partitions_changeLog] PRIMARY KEY CLUSTERED ([model_name] ASC, [table_name] ASC, [partition_name] ASC, [row_version] ASC);
GO
