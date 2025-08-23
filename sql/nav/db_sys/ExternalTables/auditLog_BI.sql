CREATE EXTERNAL TABLE [db_sys].[auditLog_BI] (
    [ID] INT NOT NULL,
    [eventBy] NVARCHAR (128) NULL,
    [eventUTCStart] DATETIME2 (1) NULL,
    [eventUTCEnd] DATETIME2 (1) NULL,
    [eventType] NVARCHAR (32) NULL,
    [eventName] NVARCHAR (64) NULL,
    [eventVersion] NVARCHAR (16) NULL,
    [eventDetail] NVARCHAR (MAX) NULL
)
    WITH (
    DATA_SOURCE = [BI],
    SCHEMA_NAME = N'db_sys',
    OBJECT_NAME = N'auditLog'
    );
GO
