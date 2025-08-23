SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**************************************************************************************************************
 Description:		List of B2B customers with incorrect default channel set up, not matching to Customer Type
 Project:			16
 Creator:			Ana Jurkic (AJ)
 Copyright:			CompanyX Limited, 2020
MOD	DATE	INITS	COMMENTS
00	200907	AJ		Created 
01	230201	AJ		Excluded following customer types B2B_CLUBSC, B2B_ETAILC, B2BRETAILC
02  250226  AJ      Migrated from old BI db

**************************************************************************************************************/

create or alter view [ext].[Customers_IncorrectDefaultChannel]

as

select
	 [No_] [Customer No]
	,[Name] [Customer Name]
	,[Customer Type]
	,[Default Channel Code]
from 
	[NAV_PROD_REPL].[dbo].[UK$Customer] 
where
	[Active Customer Sub-Status] <> 1
and	(
			([Customer Type] <> [Default Channel Code] 
        and [Customer Type] not in ('E_EXP_INFL','E_GOLD_MEM','E_SPRT_INS','NZ_WEB','','INTERNAL','DIRECT','TEST','SHOPS','B2B_CLUBSC','B2B_ETAILC','B2BRETAILC'))
		or 
            (
                [Customer Type] = 'INTERNAL' and len([Default Channel Code]) > 0)
	        )


GO