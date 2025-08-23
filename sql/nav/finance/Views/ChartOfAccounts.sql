


CREATE view [finance].[ChartOfAccounts]

as

select
	   [keyTransactionDate]
      ,[Transaction Type]
      ,[keyGLAccountNo]
      ,[keyDimensionSetID]
      ,[keyCountryCode]
      ,[Management Heading]
      ,[Management Category]
      ,[Heading Sort]
      ,[Category Sort]
      ,[main]
      ,[invert]
      ,[ma]
      ,[Channel Category]
      ,[Channel Sort]
      ,[Amount]
FROM
	[ext].[ChartOfAccounts]
GO
