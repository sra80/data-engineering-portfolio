CREATE TABLE [ext].[Channel_Grouping] (
    [Code]        INT           IDENTITY (1, 1) NOT NULL,
    [Description] NVARCHAR (20) NOT NULL,
    [deleted]     DATETIME2 (0) NULL
);
GO

ALTER TABLE [ext].[Channel_Grouping]
    ADD CONSTRAINT [PK__Channel_Grouping] PRIMARY KEY CLUSTERED ([Code] ASC);
GO
