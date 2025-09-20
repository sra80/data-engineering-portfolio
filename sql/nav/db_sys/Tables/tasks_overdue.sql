CREATE TABLE [db_sys].[tasks_overdue] (
    [source_database] NVARCHAR (32) NOT NULL,
    [task_type]       NVARCHAR (32) NOT NULL,
    [task_name]       NVARCHAR (64) NOT NULL,
    [overdue_from]    DATETIME2 (0) NOT NULL,
    [overdue_alert]   DATETIME2 (0) NULL
);
GO

ALTER TABLE [db_sys].[tasks_overdue]
    ADD CONSTRAINT [DF__tasks_overdue__overdue_from] DEFAULT (getutcdate()) FOR [overdue_from];
GO

ALTER TABLE [db_sys].[tasks_overdue]
    ADD CONSTRAINT [PK__tasks_overdue] PRIMARY KEY CLUSTERED ([source_database] ASC, [task_type] ASC, [task_name] ASC);
GO
