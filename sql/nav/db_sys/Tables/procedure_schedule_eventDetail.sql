CREATE TABLE [db_sys].[procedure_schedule_eventDetail] (
    [place_holder] UNIQUEIDENTIFIER NOT NULL,
    [eventDetail]  NVARCHAR (MAX)   NULL
);
GO

ALTER TABLE [db_sys].[procedure_schedule_eventDetail]
    ADD CONSTRAINT [PK__procedure_schedule_eventDetail] PRIMARY KEY CLUSTERED ([place_holder] ASC);
GO
