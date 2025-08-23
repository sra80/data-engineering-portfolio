CREATE TABLE [ext].[Customer_Acorn_Type] (
    [code]         TINYINT       NOT NULL,
    [cat_code]     TINYINT       NOT NULL,
    [_description] NVARCHAR (64) NOT NULL
);
GO

ALTER TABLE [ext].[Customer_Acorn_Type]
    ADD CONSTRAINT [PK__Customer_Acorn_Type] PRIMARY KEY CLUSTERED ([code] ASC);
GO

ALTER TABLE [ext].[Customer_Acorn_Type]
    ADD CONSTRAINT [FK__Customer_Acorn_Type__cat_code] FOREIGN KEY ([cat_code]) REFERENCES [ext].[Customer_Acorn_Category] ([code]);
GO
