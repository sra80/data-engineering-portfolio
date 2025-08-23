CREATE TABLE [ext].[Customer_Ecosystem] (
    [ID]        INT           NOT NULL,
    [ecosystem] NVARCHAR (32) NULL
);
GO

ALTER TABLE [ext].[Customer_Ecosystem]
    ADD CONSTRAINT [PK__Customer_Ecosystem] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
