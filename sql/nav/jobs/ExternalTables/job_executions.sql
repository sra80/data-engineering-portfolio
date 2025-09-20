-- External table mapping to Elastic Job Agent job executions
-- Note: Column list includes only fields used by procedures in this repo.
CREATE EXTERNAL TABLE [jobs].[job_executions]
(
    [job_execution_id]      UNIQUEIDENTIFIER NOT NULL,
    [job_name]              NVARCHAR(128)    NULL,
    [target_type]           NVARCHAR(32)     NULL,
    [target_database_name]  NVARCHAR(128)    NULL,
    [is_active]             BIT              NULL,
    [start_time]            DATETIME2(7)     NULL,
    [end_time]              DATETIME2(7)     NULL,
    [lifecycle]             NVARCHAR(32)     NULL,
    [last_message]          NVARCHAR(4000)   NULL
)
WITH
(
    DATA_SOURCE = [elastic_job_agent]
);
GO
