CREATE TABLE [ext].[AmazonSeller_Sales] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [Document_No]         NVARCHAR (20) NOT NULL,
    [Order_Date]          DATE          NOT NULL,
    [Posting_Date]        DATE          NOT NULL,
    [Currency_Code]       NVARCHAR (3)  NOT NULL,
    [Item_No]             NVARCHAR (20) NOT NULL,
    [Quantity]            INT           NOT NULL,
    [Sales_Amount_Actual] MONEY         NOT NULL,
    [Sales_Channel]       NVARCHAR (20) NOT NULL
);
GO

ALTER TABLE [ext].[AmazonSeller_Sales]
    ADD CONSTRAINT [pk__AmazonSeller_Sales] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
