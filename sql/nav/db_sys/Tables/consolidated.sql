CREATE TABLE [db_sys].[consolidated] (
    [table_name] NVARCHAR (128) NOT NULL,
    [addTS] DATETIME2 (1)  NOT NULL,
    [altTS] DATETIME2 (1)  NOT NULL
);
GO

ALTER TABLE [db_sys].[consolidated]
    ADD CONSTRAINT [PK__consolidated] PRIMARY KEY CLUSTERED ([table_name] ASC);
GO

ALTER TABLE [db_sys].[consolidated]
    ADD CONSTRAINT [DF__consolidated__addTS] DEFAULT (getutcdate()) FOR [addTS];
GO

ALTER TABLE [db_sys].[consolidated]
    ADD CONSTRAINT [DF__consolidated__altTS] DEFAULT (getutcdate()) FOR [altTS];
GO