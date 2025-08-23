CREATE TABLE [db_sys].[pre_model_monitor_local] (
    [place_holder]     NVARCHAR (36)    NOT NULL,
    [job_execution_id] UNIQUEIDENTIFIER NULL,
    [active]           BIT              NOT NULL,
    [addedUTC]         DATETIME         NOT NULL
);
GO

ALTER TABLE [db_sys].[pre_model_monitor_local]
    ADD CONSTRAINT [PK__pre_model_monitor] PRIMARY KEY CLUSTERED ([place_holder] ASC);
GO

ALTER TABLE [db_sys].[pre_model_monitor_local]
    ADD CONSTRAINT [DF__pre_model_monitor__active] DEFAULT ((0)) FOR [active];
GO

ALTER TABLE [db_sys].[pre_model_monitor_local]
    ADD CONSTRAINT [DF__pre_model_monitor__addedUTC] DEFAULT (getutcdate()) FOR [addedUTC];
GO
