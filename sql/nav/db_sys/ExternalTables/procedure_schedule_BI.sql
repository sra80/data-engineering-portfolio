CREATE EXTERNAL TABLE [db_sys].[procedure_schedule_BI] (
    [procedureName] NVARCHAR (64) NOT NULL,
    [schedule_disabled] BIT NOT NULL,
    [process] BIT NOT NULL,
    [process_active] BIT NOT NULL,
    [last_processed] DATETIME NULL,
    [frequency_unit] NVARCHAR (16) NOT NULL,
    [frequency_value] INT NOT NULL,
    [start_month] INT NULL,
    [start_day] INT NULL,
    [start_dow] INT NULL,
    [start_hour] INT NULL,
    [start_minute] INT NULL,
    [end_month] INT NULL,
    [end_day] INT NULL,
    [end_dow] INT NULL,
    [end_hour] INT NULL,
    [end_minute] INT NULL,
    [place_holder] UNIQUEIDENTIFIER NULL,
    [error_count] INT NOT NULL
)
    WITH (
    DATA_SOURCE = [BI],
    SCHEMA_NAME = N'db_sys',
    OBJECT_NAME = N'procedure_schedule'
    );
GO
