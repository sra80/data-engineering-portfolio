CREATE TABLE [db_sys].[hs_consolidated] (
    [table_name] NVARCHAR (128) NOT NULL,
    [addTS] DATETIME2 (1)  NOT NULL,
    [altTS] DATETIME2 (1)  NOT NULL
);
GO

ALTER TABLE [db_sys].[hs_consolidated]
    ADD CONSTRAINT [PK__hs_consolidated] PRIMARY KEY CLUSTERED ([table_name] ASC);
GO

ALTER TABLE [db_sys].[hs_consolidated]
    ADD CONSTRAINT [DF__hs_consolidated__addTS] DEFAULT (getutcdate()) FOR [addTS];
GO

ALTER TABLE [db_sys].[hs_consolidated]
    ADD CONSTRAINT [DF__hs_consolidated__altTS] DEFAULT (getutcdate()) FOR [altTS];
GO