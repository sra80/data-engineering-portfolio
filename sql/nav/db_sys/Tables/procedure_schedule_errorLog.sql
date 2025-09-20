CREATE TABLE [db_sys].[procedure_schedule_errorLog] (
    [ID]                INT                 IDENTITY (1, 1) NOT NULL,
    [procedureName]     NVARCHAR (128)       NULL,
    [auditLog_ID]       INT                 NULL,
    [errorLine]         INT                 NULL,
    [errorMessage]      NVARCHAR (MAX)      NULL,
    [dateAddedUTC]      DATETIME2 (7)       DEFAULT (getutcdate()) NULL,
    [messageSent]       DATETIME2 (7)       NULL,
    [report_error]      BIT                 NOT NULL
);
GO

ALTER TABLE [db_sys].[procedure_schedule_errorLog]
    ADD CONSTRAINT [DF__procedure_schedule_errorLog__report_error] DEFAULT ((1)) FOR [report_error];
GO

ALTER TABLE [db_sys].[procedure_schedule_errorLog]
    ADD CONSTRAINT [PK__procedure_schedule_errorLog] PRIMARY KEY CLUSTERED ([ID] ASC);
GO