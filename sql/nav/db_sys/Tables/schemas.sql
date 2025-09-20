CREATE TABLE [db_sys].[schemas] (
    [schema_name]  NVARCHAR (64) NULL,
    [schema_id]    INT           NOT NULL,
    [addedTSUTC]   DATETIME2 (1) NOT NULL,
    [updatedTSUTC] DATETIME2 (1) NULL,
    [deletedTSUTC] DATETIME2 (1) NULL
);
GO

ALTER TABLE [db_sys].[schemas]
    ADD CONSTRAINT [DF__schemas__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [db_sys].[schemas]
    ADD CONSTRAINT [PK__schemas] PRIMARY KEY CLUSTERED ([schema_id] ASC);
GO
