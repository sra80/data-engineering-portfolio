CREATE TABLE [db_sys].[procedure_schedule_handler] (
    [place_holder]     UNIQUEIDENTIFIER NOT NULL,
    [job_execution_id] UNIQUEIDENTIFIER NULL
);
GO

ALTER TABLE [db_sys].[procedure_schedule_handler]
    ADD CONSTRAINT [PK__procedure_schedule_handler] PRIMARY KEY CLUSTERED ([place_holder] ASC);
GO
