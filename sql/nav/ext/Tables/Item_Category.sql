CREATE TABLE [ext].[Item_Category] (
    [sku]      NVARCHAR (32) NOT NULL,
    [category] NVARCHAR (32) NOT NULL
);
GO

ALTER TABLE [ext].[Item_Category]
    ADD CONSTRAINT [PK__Item_Category] PRIMARY KEY CLUSTERED ([sku] ASC, [category] ASC);
GO
