CREATE TABLE [ext].[MA_Reporting_Range] (
    [_company]          TINYINT       NOT NULL,
    [keyReportingGroup] NVARCHAR (3)  NOT NULL,
    [keyLegalEntity]    NVARCHAR (4)  NOT NULL,
    [Reporting Range]   NVARCHAR (42) NOT NULL
);
GO

ALTER TABLE [ext].[MA_Reporting_Range]
    ADD CONSTRAINT [PK__MA_Reporting_Range] PRIMARY KEY CLUSTERED ([_company] ASC, [keyReportingGroup] ASC, [keyLegalEntity] ASC, [Reporting Range] ASC);
GO
