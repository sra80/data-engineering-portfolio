CREATE EXTERNAL DATA SOURCE [BI]
    WITH (
    TYPE = RDBMS,
    LOCATION = N'hs-bi-datawarehouse-sql.database.windows.net',
    DATABASE_NAME = N'BI',
    CREDENTIAL = [BI__NAV_PROD__Link]
    );
GO
