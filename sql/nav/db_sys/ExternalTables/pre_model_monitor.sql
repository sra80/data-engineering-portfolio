CREATE EXTERNAL TABLE [db_sys].[pre_model_monitor] (
    [place_holder] NVARCHAR (36) NOT NULL,
    [job_execution_id] UNIQUEIDENTIFIER NULL,
    [active] BIT NOT NULL,
    [addedUTC] DATETIME NOT NULL
)
    WITH (
    DATA_SOURCE = [elastic_job_agent]
    );
GO
