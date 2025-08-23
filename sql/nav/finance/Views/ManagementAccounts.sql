




CREATE view [finance].[ManagementAccounts]

as

select
	   [keyAccountCode]
      ,[Management Heading]
      ,[Management Category]
      ,[Heading Sort]
      ,[Category Sort]
      --,[show]
      ,[invert]
      ,[ma]
      ,[Channel Category]
      ,[Channel Sort]
from
	[ext].[ManagementAccounts]
GO
