CREATE TYPE [ext].[ty_ChartOfAccounts] AS TABLE (
    [period_date]     DATE          NOT NULL,
    [gl]              NVARCHAR (32) NOT NULL,
    [period_fom]      AS            (datefromparts(datepart(year,[period_date]),datepart(month,[period_date]),(1))) PERSISTED,
    [period_eom]      AS            (eomonth([period_date])) PERSISTED,
    [period_date_int] AS            (CONVERT([int],CONVERT([nvarchar],eomonth([period_date]),(112)))) PERSISTED,
    PRIMARY KEY NONCLUSTERED ([period_date] ASC, [gl] ASC));
GO
