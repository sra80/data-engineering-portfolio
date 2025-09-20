CREATE EXTERNAL TABLE [db_sys].[auditLog_logicApp_identifier] (
    [ID] NVARCHAR (36) NOT NULL,
    [sessionID] UNIQUEIDENTIFIER NOT NULL,
    [addedTSUTC] DATETIME2 (1) NULL,
    [is_active] BIT NOT NULL,
    [endTSUTC] DATETIME2 (1) NULL
)
    WITH (
    DATA_SOURCE = [elastic_job_agent]
    );
GO
