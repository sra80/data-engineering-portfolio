CREATE TABLE [ext].[Customer_Acorn_Category] (
    [code]         TINYINT       NOT NULL,
    [_description] NVARCHAR (64) NOT NULL
);
GO

ALTER TABLE [ext].[Customer_Acorn_Category]
    ADD CONSTRAINT [PK__Customer_Acorn_Category] PRIMARY KEY CLUSTERED ([code] ASC);
GO
