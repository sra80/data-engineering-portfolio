CREATE TABLE [db_sys].[Lookup] (
    [schemaName]  NVARCHAR (128) NOT NULL,
    [tableName]  NVARCHAR (128) NOT NULL,
    [columnName] NVARCHAR (128) NOT NULL,
    [_key]       INT           NOT NULL,
    [_value]     NVARCHAR (128) NOT NULL,
    [addedTSUTC] DATETIME2 (1) DEFAULT (getutcdate()) NOT NULL
);
GO

ALTER TABLE [db_sys].[Lookup]
    ADD CONSTRAINT [PK__Lookup] PRIMARY KEY CLUSTERED ([tableName] ASC, [columnName] ASC, [_key] ASC);
GO

/*
ALTER TABLE [db_sys].[Lookup] ADD CONSTRAINT [FK__Lookup__tableName] FOREIGN KEY (tableName) REFERENCES [db_sys].[consolidated] (table_name)
GO
*/
