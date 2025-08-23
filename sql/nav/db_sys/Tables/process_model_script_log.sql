CREATE TABLE [db_sys].[process_model_script_log] (
    [auditLog_ID]  INT            NOT NULL,
    [model_name]   NVARCHAR (32)  NOT NULL,
    [model_script] NVARCHAR (MAX) NOT NULL
);
GO

ALTER TABLE [db_sys].[process_model_script_log]
    ADD CONSTRAINT [PK__process_model_script_log] PRIMARY KEY CLUSTERED ([auditLog_ID] ASC);
GO
