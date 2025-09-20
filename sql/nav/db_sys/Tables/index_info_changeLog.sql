CREATE TABLE [db_sys].[index_info_changeLog] (
    [indexName]   NVARCHAR (64)  NOT NULL,
    [row_version] INT            NOT NULL,
    [is_current]  BIT            NOT NULL,
    [tableName]   NVARCHAR (64)  NOT NULL,
    [projectID]   INT            NOT NULL,
    [script]      NVARCHAR (MAX) NULL,
    [info]        NVARCHAR (MAX) NULL,
    [createdBy]   NVARCHAR (255) NOT NULL,
    [createdDate] DATETIME2 (0)  NOT NULL,
    [updatedBy]   NVARCHAR (255) NULL,
    [updatedDate] DATETIME2 (0)  NULL,
    [deletedBy]   NVARCHAR (255) NULL,
    [deletedDate] DATETIME2 (0)  NULL,
    [errorBlock]  BIT            NOT NULL
);
GO

ALTER TABLE [db_sys].[index_info_changeLog]
    ADD CONSTRAINT [PK__index_info_changeLog] PRIMARY KEY CLUSTERED ([indexName] ASC, [row_version] ASC);
GO
