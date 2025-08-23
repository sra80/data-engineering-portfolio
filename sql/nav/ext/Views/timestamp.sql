CREATE or ALTER VIEW [ext].[timestamp]

as

select db_sys.fn_getgmtdate() [Last Update]
GO

GRANT SELECT
    ON OBJECT::[ext].[timestamp] TO [All CompanyX Staff]
    AS [dbo];
GO
