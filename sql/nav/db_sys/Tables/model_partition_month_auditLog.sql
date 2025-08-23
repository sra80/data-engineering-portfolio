CREATE TABLE [db_sys].[model_partition_month_auditLog] (
    [model_name]  NVARCHAR(32)   NOT NULL,
    [auditLog_ID] INT            NOT NULL,
    [step]        INT            NOT NULL,
    [command]     NVARCHAR (MAX) NOT NULL,
    [addedTSUTC]  DATETIME2 (1)  NOT NULL
);
GO

ALTER TABLE [db_sys].[model_partition_month_auditLog]
    ADD CONSTRAINT [PK__model_partition_month_auditLog] PRIMARY KEY CLUSTERED ([model_name], [auditLog_ID] ASC, [step] ASC);
GO

ALTER TABLE [db_sys].[model_partition_month_auditLog]
    ADD CONSTRAINT [DF__model_partition_month_auditLog__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO