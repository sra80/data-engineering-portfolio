CREATE TABLE [stock].[forecast_ratio] (
    [base_year]  INT           NOT NULL,
    [dow]        TINYINT       NOT NULL,
    [dow_ratio]  FLOAT (53)    NOT NULL,
    [addedTSUTC] DATETIME2 (1) NOT NULL
);
GO

ALTER TABLE [stock].[forecast_ratio]
    ADD CONSTRAINT [PK__forecast_ratio] PRIMARY KEY CLUSTERED ([base_year] ASC, [dow] ASC);
GO

ALTER TABLE [stock].[forecast_ratio]
    ADD CONSTRAINT [DF__forecast_ratio__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO
