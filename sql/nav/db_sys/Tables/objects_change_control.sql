CREATE TABLE [db_sys].[objects_change_control] (
    [object_id]         INT            NOT NULL,
    [version_id]        INT            NOT NULL,
    [object_definition] NVARCHAR (MAX) NOT NULL,
    [modify_date]       DATETIME2 (3)  NULL,
    [addedTSUTC]        DATETIME2 (3)  NOT NULL
);
GO

ALTER TABLE [db_sys].[objects_change_control]
    ADD CONSTRAINT [PK__objects_change_control] PRIMARY KEY CLUSTERED ([object_id] ASC, [version_id] ASC);
GO
