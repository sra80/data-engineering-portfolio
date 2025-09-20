CREATE TABLE [db_sys].[procedure_schedule_changeLog] (
    [procedureName]     NVARCHAR (128)  NOT NULL,
    [schedule_disabled] BIT            NOT NULL,
    [frequency_unit]    NVARCHAR (16)  NULL,
    [frequency_value]   INT            NULL,
    [start_month]       INT            NULL,
    [start_day]         INT            NULL,
    [start_dow]         INT            NULL,
    [start_hour]        INT            NULL,
    [start_minute]      INT            NULL,
    [end_month]         INT            NULL,
    [end_day]           INT            NULL,
    [end_dow]           INT            NULL,
    [end_hour]          INT            NULL,
    [end_minute]        INT            NULL,
    [row_version]       INT            NOT NULL,
    [is_current]        BIT            NOT NULL,
    [addedTSUTC]        DATETIME2 (1)  NOT NULL,
    [addedBy]           NVARCHAR (128) NOT NULL,
    [deletedTSUTC]      DATETIME2 (1)  NULL,
    [deletedBy]         NVARCHAR (128) NULL
);
GO

ALTER TABLE [db_sys].[procedure_schedule_changeLog]
    ADD CONSTRAINT [PK__procedure_schedule_changeLog] PRIMARY KEY CLUSTERED ([procedureName] ASC, [row_version] ASC);
GO