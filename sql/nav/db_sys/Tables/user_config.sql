CREATE TABLE [db_sys].[user_config] (
    [username] NVARCHAR (255) NOT NULL,
    [timezone] NVARCHAR (32)  NULL
);
GO

ALTER TABLE [db_sys].[user_config]
    ADD CONSTRAINT [PK__user_config] PRIMARY KEY CLUSTERED ([username] ASC);
GO
