CREATE TABLE [db_sys].[fabric] (
    [table_name] NVARCHAR (128) NOT NULL,
    [addTS] DATETIME2 (1)  NOT NULL,
    [altTS] DATETIME2 (1)  NOT NULL
);
GO

ALTER TABLE [db_sys].[fabric]
    ADD CONSTRAINT [PK__fabric] PRIMARY KEY CLUSTERED ([table_name] ASC);
GO

ALTER TABLE [db_sys].[fabric]
    ADD CONSTRAINT [DF__fabric__addTS] DEFAULT (getutcdate()) FOR [addTS];
GO

ALTER TABLE [db_sys].[fabric]
    ADD CONSTRAINT [DF__fabric__altTS] DEFAULT (getutcdate()) FOR [altTS];
GO