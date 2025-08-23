CREATE TABLE [db_sys].[iteration] (
    [iteration] INT NOT NULL
);
GO

ALTER TABLE [db_sys].[iteration]
    ADD CONSTRAINT [PK__iteration] PRIMARY KEY CLUSTERED ([iteration] ASC);
GO
