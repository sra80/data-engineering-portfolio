CREATE EXTERNAL DATA SOURCE [elastic_job_agent]
    WITH (
    TYPE = RDBMS,
    LOCATION = N'hs-bi-datawarehouse-sql.database.windows.net',
    DATABASE_NAME = N'elastic_job_agent',
    CREDENTIAL = [elastic_job_agent__Link]
    );
GO
