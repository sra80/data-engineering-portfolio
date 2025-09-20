CREATE TABLE [db_sys].[process_model_navAutoTask_pairing] (
    [model_name]       NVARCHAR (32)    NOT NULL,
    [table_name]       NVARCHAR (64)    NOT NULL,
    [partition_name]   NVARCHAR (64)    NOT NULL,
    [navAutoTaskQueue] NVARCHAR (64)    NOT NULL,
    [navAutoTaskID]    UNIQUEIDENTIFIER NOT NULL
);
GO

ALTER TABLE [db_sys].[process_model_navAutoTask_pairing]
    ADD CONSTRAINT [PK__process_model_navAutoTask_pairing] PRIMARY KEY CLUSTERED ([model_name] ASC, [table_name] ASC, [partition_name] ASC, [navAutoTaskQueue] ASC, [navAutoTaskID] ASC);
GO
