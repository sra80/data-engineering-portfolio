CREATE TABLE [db_sys].[objects] (
    [object_id]        INT            NOT NULL,
    [schema_id]        INT            NOT NULL,
    [object_name]      NVARCHAR (255) NOT NULL,
    [object_type]      NVARCHAR (2)   NOT NULL,
    [create_date]      DATETIME2 (1)  NOT NULL,
    [modify_date]      DATETIME2 (1)  NOT NULL,
    [delete_date]      DATETIME2 (1)  NULL,
    [parent_object_id] INT            NOT NULL
);
GO

ALTER TABLE [db_sys].[objects]
    ADD CONSTRAINT [PK__objects] PRIMARY KEY CLUSTERED ([object_id] ASC);
GO
