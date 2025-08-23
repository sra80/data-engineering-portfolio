CREATE TABLE [ext].[Budget&Forecast] (
    [keyTransactionDate] INT           NOT NULL,
    [Transaction Type]   NVARCHAR (8)  NOT NULL,
    [keyGLAccountNo]     NVARCHAR (40) NOT NULL,
    [keyDimensionSetID]  INT           NOT NULL,
    [keyCountryCode]     NVARCHAR (5)  NOT NULL,
    [_company]           TINYINT       NOT NULL,
    [Amount]             DECIMAL (12)  NOT NULL
);
GO

ALTER TABLE [ext].[Budget&Forecast]
    ADD CONSTRAINT [PK__Budget&Forecast] PRIMARY KEY CLUSTERED ([keyTransactionDate] ASC, [Transaction Type] ASC, [keyGLAccountNo] ASC, [keyDimensionSetID] ASC, [keyCountryCode] ASC, [_company] ASC);
GO
