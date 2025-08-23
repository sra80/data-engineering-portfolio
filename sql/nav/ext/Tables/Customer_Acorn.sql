CREATE TABLE [ext].[Customer_Acorn] (
    [cus_code]     NVARCHAR (20) NOT NULL,
    [acorn_type]   TINYINT       NOT NULL,
    [addedTSUTC]   DATETIME2 (0) NOT NULL,
    [updatedTSUTC] DATETIME2 (0) NULL
);
GO

ALTER TABLE [ext].[Customer_Acorn]
    ADD CONSTRAINT [PK__Customer_Acorn] PRIMARY KEY CLUSTERED ([cus_code] ASC);
GO
