CREATE TABLE [ext].[ile_AmazonSeller_Sales] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [Document_No] NVARCHAR (30) NOT NULL
);
GO

ALTER TABLE [ext].[ile_AmazonSeller_Sales]
    ADD CONSTRAINT [pk__ile_AmazonSeller_Sales] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
