CREATE TABLE [db_sys].[process_model_changeLog] (
    [model_name]      NVARCHAR (32)  NOT NULL,
    [disable_process] BIT            NOT NULL,
    [start_month]     INT            NULL,
    [start_day]       INT            NULL,
    [start_dow]       INT            NULL,
    [start_hour]      INT            NULL,
    [start_minute]    INT            NULL,
    [end_month]       INT            NULL,
    [end_day]         INT            NULL,
    [end_dow]         INT            NULL,
    [end_hour]        INT            NULL,
    [end_minute]      INT            NULL,
    [row_version]     INT            NOT NULL,
    [is_current]      BIT            NOT NULL,
    [addedTSUTC]      DATETIME2 (1)  NOT NULL,
    [addedBy]         NVARCHAR (128) NOT NULL,
    [deletedTSUTC]    DATETIME2 (1)  NULL,
    [deletedBy]       NVARCHAR (128) NULL
);
GO

ALTER TABLE [db_sys].[process_model_changeLog]
    ADD CONSTRAINT [PK__process_model_changeLog] PRIMARY KEY CLUSTERED ([model_name] ASC, [row_version] ASC);
GO
