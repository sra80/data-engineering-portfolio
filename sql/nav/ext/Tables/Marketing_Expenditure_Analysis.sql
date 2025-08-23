CREATE TABLE [ext].[Marketing_Expenditure_Analysis] (
    [mc_sort]            INT           NOT NULL,
    [ma_sort]            INT           NOT NULL,
    [keyGLAccountNo]     NVARCHAR (5)  NOT NULL,
    [Marketing Channel]  NVARCHAR (20) NOT NULL,
    [Marketing Analysis] NVARCHAR (32) NOT NULL
);
GO

ALTER TABLE [ext].[Marketing_Expenditure_Analysis]
    ADD CONSTRAINT [PK__Marketing_Expenditure_Analysis] PRIMARY KEY CLUSTERED ([keyGLAccountNo] ASC);
GO
