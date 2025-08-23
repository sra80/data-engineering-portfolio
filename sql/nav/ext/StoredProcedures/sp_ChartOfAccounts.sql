SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create or alter procedure [ext].[sp_ChartOfAccounts]
	(
		 @table_ChartOfAccounts ext.ty_ChartOfAccounts readonly 
	)

as


--!!!! Check if --31 still needed!!!!

/*
 Description:		Populates [ext].[ChartOfAccounts] table
 Project:			135
 Creator:			Ana Jurkic (AJ)
 Copyright:			CompanyX Limited, 2021
MOD	DATE	INITS	COMMENTS
19			AJ		Change to reference view [finance].[MA_Dimensions] instead of [finance].[Dimensions] because due to structure change reporting ranges used in Flash are no longer suitable
					Added --and d.[Sale Channel] <> 'Intercompany' -- to exclude 'Intercompany' from 'International' sale channel
					Replaced 8 with 20 (Direct to Consumer), 11 with 23 (International) to exclude 'Intercompany' from 'International' sale channel
					Edited update statements to reflect accurate keyDimesnionSetIDs for reporting ranges and sale channel
					Added delete statement to delete data older than last year
					Change to reference [ext].[MA_Reporting_Range] instead of [ext].[Reporting_Range] because reporting ranges used in Flash are no longer suitable
20			AJ		Additional changes to case statement to replace NULLs for [keyDimensionSetID]
21			AJ		Add insert statement to ext.G_L_Entry for [dbo].[NL$G_L Entry]
					Removed delete statement for [_company] = 1 and added cross apply @table_ChartOfAccounts for Group Eliminations Actuals
22			AJ		Hardcoded country to 'NL' for insert statement ext.G_L_Entry for [dbo].[NL$G_L Entry]
					Added insert for NL Actuals
23			AJ		Added insert to ext.G_L_Entry for QC
					Added insert for QC Actuals
24	220719	AJ		Added insert for QC and CE Budget and Forecast
25	220720	AJ		Added additional join to Budget and Forecast insert due to budget name being the same across companies
26	221114	AJ		Modified coalesce(nullif(ma.[main],''),0) [main] to isnull(ma.[main],1) [main] for Budget and Forecast to isnull(ma.[main],1) [main] for actuals
					to show balances for all GLs in the model
27	221121	AJ		Added Units Sold for NL
28	221122	AJ		Added Order Count for HBV
29	221124	AJ		Changed companies and dimensionID to match new structure
					Company Code	Company Description									keyDimensionSetID
						0			Group Consolidation										
						1			UK											
						2			Group Eliminations (CE)		20000 + [Dimension Set ID]
						3			Quality Call Centre										30000 + [Dimension Set ID]
						4			CompanyX Europe										40000 + [Dimension Set ID]
30	221128	AJ		Due PK_violation changed script for MA10001 by reporting range
31	221130	AJ		To correct error on YoY measures in reporting added insert (MA10002 YTD Last Year) and update (to replace NULL with 0 for Amount) statements
32	221201	AJ		Corrected isnull(aw.[keyDimensionSetID],w.[Transaction Type]) to isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) in MA10003 by Sales Channel
33	221205	AJ		Added [_company] to budget & forecast units sold & order count insert statement
34	230117	AJ		Removed keyDimensionSetId 23 and Sale Channel International as no longer required for reporting
					(overwriting recorded sale channel to report International based on the country is no longer required - recorded sale channel will be reported as is, 
					unless it's blank or International, in which case it will be reported as Direct to Consumer)
35	230123	AJ		Company Code	Company Description		keyDimensionSetID
						5			Healthsapn New Zealand	50000 + [Dimension Set ID]
					Add insert statement to ext.G_L_Entry for [dbo].[NZ$G_L Entry]
					Added insert for HSNZ Actuals
					Added Units Sold for HSNZ 
					Added Order Count for HSNZ
36	230125	AJ		Added budget & forecast for NL & HSNZ
					Modified insert into ext.G_L_Entry for CE ('ZZ') and QC (GG)
37	230130	AJ		Added MA10003 & MA10007 by Jurisdiction
38	230201	AJ		Removed insert for --31 ACTUAL - YTD Last Year - NL as no longer needed, data now available for YTD Last Year
39	230223	AJ		MA10004, MA10006 & MA10008 budget & forecast need to be recalculated on every load
					Modified Load Budget NL, Load Budget HSNZ, Load Forecast NL and Load Forecast HSNZ so that last Exchange Rate Amount is used for future months because future rates don't exist and budget & forecast otherwise 
					don't get imported for future months
40	230401	AJ		Company Code	Company Description		keyDimensionSetID
						6			Healthsapn Ireland	60000 + [Dimension Set ID]
					Add insert statement to ext.G_L_Entry for [dbo].[IE$G_L Entry]
					Added insert for HSIE Actuals
					Added Units Sold for HSIE 
					Added Order Count for HSIE
					Added budget & forecast for HSIE
41  230320 AJ		Modified calculation for currency conversion for actuals 
42	230330 AJ		Renamed metrics
						Gross Profit/(Loss) - Contribution Margin (CM1)
					Added calculations for Total Net Sales (MA10009) & Total Cost of Sales (MA10010) - Actuals, Budget and Forecast
43	230501	AJ		Removed MA10002 - ACTUAL - YTD This Year - HSIE; no longer needed
44	230731	AJ		Changed logic for Starting Date & Ending date for Actual, Budget and Forecast load for HSIE, HSNZ, HSVB
45	230801	AJ		For optimisation purposes replaced cross apply with join to @table_ChartOfAccounts t
46	240101	AJ		Commented out --31 ACTUAL - YTD LAST YEAR for HSNZ & HSIE as no longer required
47	240129	AJ		Commented in --31 ACTUAL - YTD LAST YEAR for HSIE as CompanyX Ireland tab in the report errors out
48	240130	AJ		Modified Load Budget & Forecast for NL, HSNZ & HSIE so that in Jan Ending Date for last Exchange Rate extend to the end of current year
49  240430  AJ      Removed MA10002 - ACTUAL - YTD This Year - HSIE; no longer needed
50  240626  AJ      Added insert for MA10002 - ACTUAL - YTD This Year - NL otherwise  CompanyX Europe tab in the report errors out
51	241129	AJ		Modified insert into ext.G_L_Entry to only insert non-close income entries (and convert(time(0),[Posting Date]) = '00:00:00')
                    Modified insert for Actuals for HS SELL, Group Elimination and, QC to only include non-close income entries (and convert(time(0),[Posting Date]) = '00:00:00')
                    NL, HSNZ and HSIE don't need to be changed as non-close income entries are already excluded by the join to Currency Exchange Rate table
52  250108  AJ      Modified the logic for [Starting Date] & [Ending Date] for Budget and Forecast load for HSIE, HSNZ, HSVB
53	250113	AJ		Excluded NutraQ (110) from following inserts
                        Load Actuals - UK
                        ACTUAL UNITS SOLD -- UK (MA10000)
                        ACTUAL ORDER COUNT BY SALES CHANNEL--UK (MA10001)
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --UK (MA10001) - No need to exclude NutraQ (110) as it's already excluded by the join to ext.MA_Reporting_Range
                    Modified join to @table_ChartOfAccounts from eomonth([Posting Date]) = t.period_eom to [Posting Date] >= t.period_fom and [Posting Date] <= t.period_eom for optimization in following inserts
                        Load Actuals - UK
                        Load Actuals - Group Eliminations
                        Load Actuals - QC
                        Load Actuals - NL
                        Load Actuals - HSNZ
                        Load Actuals - HSIE
                        ACTUAL ORDER COUNT BY SALES CHANNEL--UK (MA10001)
                        ACTUAL ORDER COUNT BY SALES CHANNEL--NL (MA10001)
                        ACTUAL ORDER COUNT BY SALES CHANNEL--HSNZ (MA10001)
                        ACTUAL ORDER COUNT BY SALES CHANNEL--HSIE (MA10001)
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --UK (MA10001)
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --NL (MA10001)
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --HSIE (MA10001)
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --HSNZ (MA10001)
                    Removed the filter on abs([Quantity]) > 0 for Sales Invoice Line tables as no longer needed in any of the companies
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --UK (MA10001)
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --NL (MA10001)
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --HSIE (MA10001)
                        ACTUAL -- ORDER COUNT BY REPORTING RANGE --HSNZ (MA10001)
                        ACTUAL ORDER COUNT BY SALES CHANNEL--UK (MA10001)
                        ACTUAL ORDER COUNT BY SALES CHANNEL--NL (MA10001)
                        ACTUAL ORDER COUNT BY SALES CHANNEL--HSNZ (MA10001)
                        ACTUAL ORDER COUNT BY SALES CHANNEL--HSIE (MA10001)
                    ACTUAL -- ORDER COUNT BY REPORTING RANGE --UK (MA10001)
                        No need to exclude NutraQ (110) as it's already excluded by the join to ext.MA_Reporting_Range
54  250113  AJ      Added ACTUAL - YTD This Year - HSNZ and ACTUAL - YTD This Year - HSNZ; otherwise CompanyX Europe and CompanyX New Zealand tabs on the report error out
55  250416  AJ      Modified join @table_ChartOfAccounts from eomonth([Posting Date]) = t.period_eom to [Posting Date] >= t.period_fom and [Posting Date] <= t.period_eom for optimization in following inserts
                        --ACTUAL UNITS SOLD--UK
                        --ACTUAL UNITS SOLD--NL
                        --ACTUAL UNITS SOLD--HSNZ
                        --ACTUAL UNITS SOLD--HSIE
56	250425	AJ		Modified scripts for MA10001 - ACTUAL ORDER COUNT BY SALES CHANNEL due to performance issues
*/


set nocount on

declare @getdate date = getdate(), @last_ext_entry_no int

--populate ext.G_L_Entry //if needing to truncate & repopulate --insert only data going back to begining of year before last//
/*!!!DON'T TRUNCATE THE TABLE!!! ext.fn_gl_country function is referencing Sales Shipment Header table to retrive the country, which in NAV no loger holds data with a Posting Date older than 6 months*/
/*if country_region is ever needed from sales shipments older than 6 months, it can be found in the item ledger entry*/

--UK --29 --51
insert into ext.G_L_Entry (entry_no, posting_date, country_region) select [Entry No_],[Posting Date],ext.fn_gl_country(1,[Document No_],[Source No_],[Description]) from [dbo].[UK$G_L Entry] where [Entry No_] > (select max(entry_no) from ext.G_L_Entry where [_company] = 1) and convert(time(0),[Posting Date]) = '00:00:00'
--CE --29 & 36 --51
insert into ext.G_L_Entry (_company, entry_no, posting_date, country_region) select 2, [Entry No_],[Posting Date],/*ext.fn_gl_country([Document No_],[Source No_],[Description])*/'ZZ' from [dbo].[CE$G_L Entry] where [Entry No_] > (select max(entry_no) from ext.G_L_Entry where [_company] = 2) and convert(time(0),[Posting Date]) = '00:00:00'
--QC --23 & 36 --51
insert into ext.G_L_Entry (_company, entry_no, posting_date, country_region) select 3, [Entry No_],[Posting Date],'GG' from [dbo].[QC$G_L Entry] where [Entry No_] > (select max(entry_no) from ext.G_L_Entry where [_company] = 3) and convert(time(0),[Posting Date]) = '00:00:00'
--NL --21 & 22 & 29 --51
insert into ext.G_L_Entry (_company, entry_no, posting_date, country_region) select 4, [Entry No_],[Posting Date],'NL' from [dbo].[NL$G_L Entry] where [Entry No_] > (select max(entry_no) from ext.G_L_Entry where [_company] = 4) and convert(time(0),[Posting Date]) = '00:00:00'
--HSNZ --35 --51
insert into ext.G_L_Entry (_company, entry_no, posting_date, country_region) select 5, [Entry No_],[Posting Date],'NZ' from [dbo].[NZ$G_L Entry] where [Entry No_] > (select max(entry_no) from ext.G_L_Entry where [_company] = 5) and convert(time(0),[Posting Date]) = '00:00:00'
--HSIE --40 --51
insert into ext.G_L_Entry (_company, entry_no, posting_date, country_region) select 6, [Entry No_],[Posting Date],ext.fn_gl_country(6,[Document No_],[Source No_],[Description]) from [dbo].[IE$G_L Entry] where [Entry No_] > (select max(entry_no) from ext.G_L_Entry where [_company] = 6) and convert(time(0),[Posting Date]) = '00:00:00'


select @last_ext_entry_no = max(entry_no) from ext.G_L_Entry 

if (select sum(1) from @table_ChartOfAccounts) > 0 delete from ext.ChartOfAccounts where exists (select 1 from @table_ChartOfAccounts t where ChartOfAccounts.keyTransactionDate = t.period_date_int and ChartOfAccounts.keyGLAccountNo = t.gl) --and [Transaction Type] = 'Actual' 
delete from ext.ChartOfAccounts where [Transaction Type] in ('Budget','Forecast') and keyGLAccountNo not in ('MA10002','MA10003',/*'MA10004',*/'MA10005',/*'MA10006',*/'MA10007'/*,'MA10008'*/) --39
--edited to delete entries for last month last year and reinsert on every load
delete from ext.ChartOfAccounts where [Transaction Type] in ('Actual','Forecast','Budget') and keyGLAccountNo in ('MA10002','MA10003','MA10005','MA10007') and ([keyTransactionDate] in (0,1,2,3) or [keyTransactionDate] = convert(int,format(eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))),'yyyyMMdd')))  

--MA10009 - Total Net Sales --42
--MA10010 - Total Cost of Sales --42
--MA10004 - Total Direct Expenses
--MA10006 - Total Overheads
--MA10008 - Total Other Income and Expenses
--MA10000 - Units Sold
--MA10001 - Order Count
--MA10002 - Average Order Value
--MA10003 - Gross Margin %
--MA10005 - Contribution Margin (CM1) % --42
--MA10007 - EBITDA % of Net Sales



--Load Budget UK
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Budget' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,[Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
    ,sum
		(case
			when ma.invert = 1
			then -dbo.[Amount]
			else dbo.[Amount]
			end) [Amount]
from
    [dbo].[UK$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_base = 1
	and ext.[_company] = 1 --25 & 29
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]


--Load Budget - Group Eliminations --24
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Budget' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,20000 + [Dimension Set ID] [keyDimensionSetID] --29
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,2 [_company] --29
    ,sum
		(case
			when ma.invert = 1
			then -dbo.[Amount]
			else dbo.[Amount]
			end) [Amount]
from
   [dbo].[CE$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_base = 1
	and ext.[_company] = 2 --25 & 29
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]


--Load Budget QC --24
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Budget' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,30000 + [Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,3 [_company]
    ,sum
		(case
			when ma.invert = 1
			then -dbo.[Amount]
			else dbo.[Amount]
			end) [Amount]
from
   [dbo].[QC$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_base = 1
	and ext.[_company] = 3 --25
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]

--Load Budget NL --36
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Budget' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,40000 + [Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,4 [_company]
    ,sum
		(case
			when ma.invert = 1
			then -(dbo.[Amount]/x.[Exchange Rate Amount]) 
			else (dbo.[Amount]/x.[Exchange Rate Amount])
			end) [Amount]
from
    [dbo].[NL$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_base = 1
	and ext.[_company] = 4 
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
join
	(
		select 
            --52
            /*
			 datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date] --[Starting Date] --44
			,case 
				when month(@getdate) = 1 then isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date])+1,month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31))
				else isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31))
			 end [Ending Date] --48
			--,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date] --39 --44 --48
			,[Exchange Rate Amount]
            */
             case
                when month([Starting Date]) = 12 and year(getdate())-2 = year([Starting Date])
                then dateadd(day,1,[Starting Date])
                else [Starting Date]
             end [Starting Date]
            ,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31)) [Ending Date] 
            ,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'EUR'
	) x
on
	dbo.[Date] >= x.[Starting Date]
and dbo.[Date] <= x.[Ending Date]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]


--Load Budget HSNZ --36
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Budget' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,50000 + [Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,5 [_company]
    ,sum
		(case
			when ma.invert = 1
			then -(dbo.[Amount]/x.[Exchange Rate Amount]) 
			else (dbo.[Amount]/x.[Exchange Rate Amount])
			end) [Amount]
from
    [dbo].[NZ$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_base = 1
	and ext.[_company] = 5
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
join
	(
		select 
			 --52
            /*
			 datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date] --[Starting Date] --44
			,case 
				when month(@getdate) = 1 then isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date])+1,month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31))
				else isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31))
			 end [Ending Date] --48
			--,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date] --39 --44 --48
			,[Exchange Rate Amount]
            */
             case
                when month([Starting Date]) = 12 and year(getdate())-2 = year([Starting Date])
                then dateadd(day,1,[Starting Date])
                else [Starting Date]
             end [Starting Date]
            ,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31)) [Ending Date] 
            ,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'NZD'
	) x
on
	dbo.[Date] >= x.[Starting Date]
and dbo.[Date] <= x.[Ending Date]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]

--Load Budget HSIE --40
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Budget' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,60000 + [Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,6 [_company]
    ,sum
		(case
			when ma.invert = 1
			then -(dbo.[Amount]/x.[Exchange Rate Amount]) 
			else (dbo.[Amount]/x.[Exchange Rate Amount])
			end) [Amount]
from
    [dbo].[IE$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_base = 1
	and ext.[_company] = 6
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
join
	(
		select 
			 --52
            /*
			 datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date] --[Starting Date] --44
			,case 
				when month(@getdate) = 1 then isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date])+1,month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31))
				else isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31))
			 end [Ending Date] --48
			--,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date] --39 --44 --48
			,[Exchange Rate Amount]
            */
             case
                when month([Starting Date]) = 12 and year(getdate())-2 = year([Starting Date])
                then dateadd(day,1,[Starting Date])
                else [Starting Date]
             end [Starting Date]
            ,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31)) [Ending Date] 
            ,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'EUR'
	) x
on
	dbo.[Date] >= x.[Starting Date]
and dbo.[Date] <= x.[Ending Date]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]

--Load Forecast UK
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Forecast' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,[Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
    ,sum
		(case
			when ma.invert = 1
			then -dbo.[Amount]
			else dbo.[Amount]
			end) [Amount]
from
        [dbo].[UK$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_comparative = 1
	and ext.[_company] = 1 --25 & 29
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]


--Load Forecast - Group Eliminations --24
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Forecast' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,20000 + [Dimension Set ID] [keyDimensionSetID] --29
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,2 [_company] --29
    ,sum
		(case
			when ma.invert = 1
			then -dbo.[Amount]
			else dbo.[Amount]
			end) [Amount]
from
	[dbo].[CE$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_comparative = 1
	and ext.[_company] = 2 --25 & 29
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]


--Load Forecast QC --24
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Forecast' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,30000 + [Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,3 [_company]
    ,sum
		(case
			when ma.invert = 1
			then -dbo.[Amount]
			else dbo.[Amount]
			end) [Amount]
from
	[dbo].[QC$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_comparative = 1
	and ext.[_company] = 3 --25
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]


--Load Forecast NL --36
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Forecast' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,40000 + [Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,4 [_company]
    ,sum
		(case
			when ma.invert = 1
			then -(dbo.[Amount]/x.[Exchange Rate Amount]) 
			else (dbo.[Amount]/x.[Exchange Rate Amount])
			end) [Amount]
from
    [dbo].[NL$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_comparative = 1
	and ext.[_company] = 4 
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
join
	(
		select 
			 --52
            /*
			 datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date] --[Starting Date] --44
			,case 
				when month(@getdate) = 1 then isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date])+1,month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31))
				else isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31))
			 end [Ending Date] --48
			--,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date] --39 --44 --48
			,[Exchange Rate Amount]
            */
             case
                when month([Starting Date]) = 12 and year(getdate())-2 = year([Starting Date])
                then dateadd(day,1,[Starting Date])
                else [Starting Date]
             end [Starting Date]
            ,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31)) [Ending Date] 
            ,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'EUR'
	) x
on
	dbo.[Date] >= x.[Starting Date]
and dbo.[Date] <= x.[Ending Date]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]


--Load Forecast HSNZ --36
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Forecast' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,50000 + [Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,5 [_company]
    ,sum
		(case
			when ma.invert = 1
			then -(dbo.[Amount]/x.[Exchange Rate Amount]) 
			else (dbo.[Amount]/x.[Exchange Rate Amount])
			end) [Amount]
from
    [dbo].[NZ$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_comparative = 1
	and ext.[_company] = 5
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
join
	(
		select 
			--52
            /*
			 datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date] --[Starting Date] --44
			,case 
				when month(@getdate) = 1 then isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date])+1,month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31))
				else isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31))
			 end [Ending Date] --48
			--,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date] --39 --44 --48
			,[Exchange Rate Amount]
            */
             case
                when month([Starting Date]) = 12 and year(getdate())-2 = year([Starting Date])
                then dateadd(day,1,[Starting Date])
                else [Starting Date]
             end [Starting Date]
            ,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31)) [Ending Date] 
            ,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'NZD'
	) x
on
	dbo.[Date] >= x.[Starting Date]
and dbo.[Date] <= x.[Ending Date]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]

--Load Forecast HSIE --40
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode], [Management Heading], [Management Category], [Heading Sort], [Category Sort], [main], [invert], [ma], [Channel Category], [Channel Sort], [_company], [Amount])
select
	 convert(int,format(eomonth([Date]),'yyyyMMdd')) [keyTransactionDate]
    ,'Forecast' [Transaction Type]
    ,[G_L Account No_] [keyAccountCode]
	,60000 + [Dimension Set ID] [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1)  [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0)  [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(ma.[Channel Sort],0) [Channel Sort]
	,6 [_company]
    ,sum
		(case
			when ma.invert = 1
			then -(dbo.[Amount]/x.[Exchange Rate Amount]) 
			else (dbo.[Amount]/x.[Exchange Rate Amount])
			end) [Amount]
from
    [dbo].[IE$G_L Budget Entry] dbo
join
    [ext].[G_L_Budget_Entry] ext
on
    (
        dbo.[Budget Name] = ext.[Budget Name]
    and ext.is_comparative = 1
	and ext.[_company] = 6
	)
left join
	[ext].[ManagementAccounts] ma
on
	dbo.[G_L Account No_] = ma.[keyAccountCode]
join
	(
		select 
			--52
            /*
			 datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date] --[Starting Date] --44
			,case 
				when month(@getdate) = 1 then isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date])+1,month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31))
				else isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31))
			 end [Ending Date] --48
			--,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date] --39 --44 --48
			,[Exchange Rate Amount]
            */
             case
                when month([Starting Date]) = 12 and year(getdate())-2 = year([Starting Date])
                then dateadd(day,1,[Starting Date])
                else [Starting Date]
             end [Starting Date]
            ,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date])+1,12,31)) [Ending Date] 
            ,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'EUR'
	) x
on
	dbo.[Date] >= x.[Starting Date]
and dbo.[Date] <= x.[Ending Date]
where
	[Date] >= dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1))  
group by
     eomonth([Date])
    ,[G_L Account No_] 
    ,[Dimension Set ID]
	,ma.[Management Heading]
	,ma.[Management Category]
	,ma.[Heading Sort]
	,ma.[Category Sort]
	,ma.[main]
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category]
	,ma.[Channel Sort]

--Load Actuals - UK
;with x as
(
select
    t.period_date_int [keyTransactionDate]
    ,'Actual' [Transaction Type]
    ,gle.[G_L Account No_] [keyGLAccountNo]
    ,gle.[Dimension Set ID] [keyDimensionSetID]
	,(select country_region from ext.G_L_Entry e where gle.[Entry No_] = e.entry_no and [_company] = 1) [keyCountryCode] --29
    ,gle.[Amount] [Amount]
from
    [dbo].[UK$G_L Entry] gle
--cross apply --45
join
    @table_ChartOfAccounts t
on
	(
		-- eomonth(gle.[Posting Date]) = t.period_eom --53 replaced with below for optimization
        gle.[Posting Date] >= t.period_fom 
    and gle.[Posting Date] <= t.period_eom
	and gle.[G_L Account No_] = t.gl
	)
where
--    gle.[Posting Date] >= t.period_fom
--and gle.[Posting Date] <= t.period_eom
--and gle.[G_L Account No_] = t.gl
--and 
	gle.[Entry No_] <= @last_ext_entry_no
and convert(time(0),[Posting Date]) = '00:00:00' --51
and gle.[Global Dimension 2 Code] <> '110' --53
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
   	,ma.[Management Category]
   	,ma.[Heading Sort]
   	,ma.[Category Sort]
   	,ma.[main]
	,ma.[invert]
   	,ma.[ma]
   	,ma.[Channel Category]
   	,ma.[Channel Sort]


--21
--Load Actuals - Group Eliminations
;with x as
(
select
	 2 [_company] --29
    ,t.period_date_int [keyTransactionDate]
    ,'Actual' [Transaction Type]
    ,gle.[G_L Account No_] [keyGLAccountNo]
    ,20000 + gle.[Dimension Set ID] [keyDimensionSetID] --29
	,'ZZ' [keyCountryCode] --29 & 36
	--(select country_region from ext.G_L_Entry e where gle.[Entry No_] = e.entry_no and [_company] = 2) [keyCountryCode] --29
    ,gle.[Amount] [Amount]
from
    [dbo].[CE$G_L Entry] gle
--cross apply --45
join
    @table_ChartOfAccounts t
on
	(
		-- eomonth(gle.[Posting Date]) = t.period_eom --53 replaced with below for optimization
        gle.[Posting Date] >= t.period_fom 
    and gle.[Posting Date] <= t.period_eom
	and gle.[G_L Account No_] = t.gl
	)
where
--    gle.[Posting Date] >= t.period_fom
--and gle.[Posting Date] <= t.period_eom
--and gle.[G_L Account No_] = t.gl
--and 
	gle.[Entry No_] <= @last_ext_entry_no
and convert(time(0),[Posting Date]) = '00:00:00' --51
)

insert into ext.ChartOfAccounts ([_company],[keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 x.[_company] 
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[_company]
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
   	,ma.[Management Category]
   	,ma.[Heading Sort]
   	,ma.[Category Sort]
   	,ma.[main]
	,ma.[invert]
   	,ma.[ma]
   	,ma.[Channel Category]
   	,ma.[Channel Sort]

--Load Actuals - QC --23
;with x as
(
select
	 3 [_company]
    ,t.period_date_int [keyTransactionDate]
    ,'Actual' [Transaction Type]
    ,gle.[G_L Account No_] [keyGLAccountNo]
    ,30000 + gle.[Dimension Set ID] [keyDimensionSetID]
	,'GG' [keyCountryCode] --36
	--,(select country_region from ext.G_L_Entry e where gle.[Entry No_] = e.entry_no and [_company] = 3) [keyCountryCode]
    ,gle.[Amount] [Amount]
from
    [dbo].[QC$G_L Entry] gle
--cross apply --45
join
    @table_ChartOfAccounts t
on
	(
		-- eomonth(gle.[Posting Date]) = t.period_eom --53 replaced with below for optimization
        gle.[Posting Date] >= t.period_fom 
    and gle.[Posting Date] <= t.period_eom
	and gle.[G_L Account No_] = t.gl
	)
where
--    gle.[Posting Date] >= t.period_fom
--and gle.[Posting Date] <= t.period_eom
--and gle.[G_L Account No_] = t.gl
--and 
	gle.[Entry No_] <= @last_ext_entry_no
and convert(time(0),[Posting Date]) = '00:00:00' --51
)

insert into ext.ChartOfAccounts ([_company],[keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 x.[_company] 
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[_company]
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
   	,ma.[Management Category]
   	,ma.[Heading Sort]
   	,ma.[Category Sort]
   	,ma.[main]
	,ma.[invert]
   	,ma.[ma]
   	,ma.[Channel Category]
   	,ma.[Channel Sort]


--Load Actuals - NL --22
;with x as
(
select
	 4 [_company] --29
    ,t.period_date_int [keyTransactionDate]
    ,'Actual' [Transaction Type]
    ,gle.[G_L Account No_] [keyGLAccountNo]
    ,40000 + gle.[Dimension Set ID] [keyDimensionSetID] --29
	,'NL' [keyCountryCode]
    ,gle.[Amount]/x.[Exchange Rate Amount] [Amount] --converts from EUR to GBP
from
	[dbo].[NL$G_L Entry]  gle
join
	(
		select 
			 datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date]--[Starting Date] --44
			,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date] --,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]  --44
			,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'EUR'
	) x
on
	gle.[Posting Date] >= x.[Starting Date]
and gle.[Posting Date] <= x.[Ending Date]
--cross apply --45
join
    @table_ChartOfAccounts t
on
	(
		-- eomonth(gle.[Posting Date]) = t.period_eom --53 replaced with below for optimization
        gle.[Posting Date] >= t.period_fom 
    and gle.[Posting Date] <= t.period_eom
	and gle.[G_L Account No_] = t.gl
	)
where
--    gle.[Posting Date] >= t.period_fom
--and gle.[Posting Date] <= t.period_eom
--and gle.[G_L Account No_] = t.gl
--and 
	gle.[Entry No_] <= @last_ext_entry_no
)

insert into ext.ChartOfAccounts ([_company],[keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 x.[_company] 
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[_company]
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
   	,ma.[Management Category]
   	,ma.[Heading Sort]
   	,ma.[Category Sort]
   	,ma.[main]
	,ma.[invert]
   	,ma.[ma]
   	,ma.[Channel Category]
   	,ma.[Channel Sort]


--Load Actuals - HSNZ --35
;with x as
(
select
	 5 [_company] 
    ,t.period_date_int [keyTransactionDate]
    ,'Actual' [Transaction Type]
    ,gle.[G_L Account No_] [keyGLAccountNo]
    ,50000 + gle.[Dimension Set ID] [keyDimensionSetID] 
	,'NZ' [keyCountryCode]
    ,gle.[Amount]/x.[Exchange Rate Amount] [Amount] --converts from NZD to GBP
from
	[dbo].[NZ$G_L Entry]  gle
join
	(
		select 
			datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date]--[Starting Date] --44
			,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date] --,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]  --44
			,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'NZD'
	) x
on
	gle.[Posting Date] >= x.[Starting Date]
and gle.[Posting Date] <= x.[Ending Date]
--cross apply --45
join
    @table_ChartOfAccounts t
on
	(
		-- eomonth(gle.[Posting Date]) = t.period_eom --53 replaced with below for optimization
        gle.[Posting Date] >= t.period_fom 
    and gle.[Posting Date] <= t.period_eom
	and gle.[G_L Account No_] = t.gl
	)
where
--    gle.[Posting Date] >= t.period_fom
--and gle.[Posting Date] <= t.period_eom
--and gle.[G_L Account No_] = t.gl
--and 
	gle.[Entry No_] <= @last_ext_entry_no 
)

insert into ext.ChartOfAccounts ([_company],[keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 x.[_company] 
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[_company]
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
   	,ma.[Management Category]
   	,ma.[Heading Sort]
   	,ma.[Category Sort]
   	,ma.[main]
	,ma.[invert]
   	,ma.[ma]
   	,ma.[Channel Category]
   	,ma.[Channel Sort]



--Load Actuals - HSIE --40
;with x as
(
select
	 6 [_company] 
    ,t.period_date_int [keyTransactionDate]
    ,'Actual' [Transaction Type]
    ,gle.[G_L Account No_] [keyGLAccountNo]
    ,60000 + gle.[Dimension Set ID] [keyDimensionSetID] 
	,isnull((select country_region from ext.G_L_Entry e where gle.[Entry No_] = e.entry_no and [_company] = 6),'ZZ') [keyCountryCode] --43
    ,gle.[Amount]/x.[Exchange Rate Amount] [Amount] --converts from NZD to GBP
from
	[dbo].[IE$G_L Entry]  gle
join
	(
		select 
			datefromparts(year([Starting Date]),month([Starting Date]),1) [Starting Date]--[Starting Date] --44
			,isnull(dateadd(day,-1,lead(datefromparts(year([Starting Date]),month([Starting Date]),1)) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]--,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),datefromparts(year([Starting Date]),12,31)) [Ending Date] --,isnull(dateadd(day,-1,lead([Starting Date]) over (order by [Currency Code],[Starting Date])),dateadd(month,1,eomonth([Starting Date]))) [Ending Date]  --44
			,[Exchange Rate Amount]
		from
			[dbo].[UK$Currency Exchange Rate] cer
		where
			[Currency Code] = 'EUR'
	) x
on
	gle.[Posting Date] >= x.[Starting Date]
and gle.[Posting Date] <= x.[Ending Date]
--cross apply --45
join
    @table_ChartOfAccounts t
on
	(
		-- eomonth(gle.[Posting Date]) = t.period_eom --53 replaced with below for optimization
        gle.[Posting Date] >= t.period_fom 
    and gle.[Posting Date] <= t.period_eom
	and gle.[G_L Account No_] = t.gl
	)
where
--    gle.[Posting Date] >= t.period_fom
--and gle.[Posting Date] <= t.period_eom
--and gle.[G_L Account No_] = t.gl
--and 
	gle.[Entry No_] <= @last_ext_entry_no
)

insert into ext.ChartOfAccounts ([_company],[keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 x.[_company] 
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[_company]
	,x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
   	,ma.[Management Category]
   	,ma.[Heading Sort]
   	,ma.[Category Sort]
   	,ma.[main]
	,ma.[invert]
   	,ma.[ma]
   	,ma.[Channel Category]
   	,ma.[Channel Sort]


--Total Net Sales - ACTUAL --42
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company]
	from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		,period_date_int
		,[_company]
	from	
		(
		select 
			 [keyTransactionDate]
			,[Transaction Type]
			,'MA10009' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company]
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Net Sales'
		and [Transaction Type] = 'Actual' --39
	) coa
--cross apply --45
join
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10009'
	) t
--where
on
	(
		[keyTransactionDate] = t.[period_date_int]
	)
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company]
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company]

--Total Net Sales - BUDGET & FORECAST --42
; with x as
(
select
	 a.[keyTransactionDate] --period_date_int [keyTransactionDate] --39
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company]
	from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		--,period_date_int  --39
		,[_company]
	from	
		(
		select 
			 [keyTransactionDate]
			,[Transaction Type]
			,'MA10009' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company]
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Net Sales'
		and [Transaction Type] in ('Budget','Forecast') --39
	) coa
	--39
	/*cross apply
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10009'
	) t
where
	[keyTransactionDate] = t.[period_date_int]*/
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company]
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company]


--Total Cost of Sales - ACTUAL --42
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company]
	from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		,period_date_int
		,[_company]
	from	
		(
		select 
			 [keyTransactionDate]
			,[Transaction Type]
			,'MA10010' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company]
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Cost of Sales'
		and [Transaction Type] = 'Actual' --39
	) coa
--cross apply --45
join
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10010'
	) t
--where
on
	(
		[keyTransactionDate] = t.[period_date_int]
	)
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company]
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company]

--Total Cost of Sales - BUDGET & FORECAST --42
; with x as
(
select
	 a.[keyTransactionDate] --period_date_int [keyTransactionDate] --39
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company]
	from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		--,period_date_int  --39
		,[_company]
	from	
		(
		select 
			 [keyTransactionDate]
			,[Transaction Type]
			,'MA10010' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company]
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Cost of Sales'
		and [Transaction Type] in ('Budget','Forecast') --39
	) coa
	--39
	/*cross apply
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10010'
	) t
where
	[keyTransactionDate] = t.[period_date_int]*/
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company]
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company]


--Total Direct Expenses - ACTUAL
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company]
	from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		,period_date_int
		,[_company]
	from	
		(
		select 
			 [keyTransactionDate]
			,[Transaction Type]
			,'MA10004' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company]
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Direct Expenses'
		and [Transaction Type] = 'Actual' --39
	) coa
	--cross apply --45
join
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10004'
	) t
--where
on
	(
		[keyTransactionDate] = t.[period_date_int]
	)
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company]
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company]

--Total Direct Expenses - BUDGET & FORECAST
; with x as
(
select
	 a.[keyTransactionDate] --period_date_int [keyTransactionDate] --39
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company]
	from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		--,period_date_int  --39
		,[_company]
	from	
		(
		select 
			 [keyTransactionDate]
			,[Transaction Type]
			,'MA10004' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company]
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Direct Expenses'
		and [Transaction Type] in ('Budget','Forecast') --39
	) coa
	--39
	/*cross apply
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10004'
	) t
where
	[keyTransactionDate] = t.[period_date_int]*/
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company]
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company]


--Total Overheads - ACTUAL
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company] --29
from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		,period_date_int
		,[_company] --29
	from	
		(select 
		 [keyTransactionDate]
		,[Transaction Type]
		,'MA10006' [keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		,[_company]
	from	
		[ext].[ChartOfAccounts]
	where
		[Management Heading] = 'Overheads'
	and [Transaction Type] = 'Actual' --39
	) coa
	--cross apply --45
join
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10006'
	) t
--where
on
	(
		[keyTransactionDate] = t.[period_date_int]
	)
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company] --29
from
    x
left join
    [ext].[ManagementAccounts] ma
on x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company] --29

--Total Overheads - BUDGET & FORECAST
; with x as
(
select
	 a.[keyTransactionDate] --period_date_int [keyTransactionDate] --39
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company] --29
from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		--,period_date_int  --39
		,[_company] --29
	from	
		(
		select 
				[keyTransactionDate]
			,[Transaction Type]
			,'MA10006' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company]
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Overheads'
		and [Transaction Type] in ('Budget','Forecast') --39
	) coa
	--39
	/*cross apply
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10006'
	) t
where
	[keyTransactionDate] = t.[period_date_int]*/
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company] --29
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company] --29


--Total Other Income and Expenses - ACTUAL
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company] --29
from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		,period_date_int
		,[_company] --29
	from	
		(
		select 
			 [keyTransactionDate]
			,[Transaction Type]
			,'MA10008' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company] --29
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Other Income and Expenses'
		and [Transaction Type] = 'Actual' --39
	) coa
--cross apply --45
join
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10008'
	) t
--where
on
	(
		[keyTransactionDate] = t.[period_date_int]
	)
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company] --29
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company] --29


--Total Other Income and Expenses - BUDGET & FORECAST
; with x as
(
select
	 a.[keyTransactionDate] --period_date_int [keyTransactionDate] --39
	,a.[Transaction Type]
	,a.[keyGLAccountNo]
	,a.[keyDimensionSetID]
	,a.[keyCountryCode]
	,a.[Amount]
	,a.[_company] --29
from
	(
	select 
		 [keyTransactionDate]
		,[Transaction Type]
		,[keyGLAccountNo]
		,[keyDimensionSetID]
		,[keyCountryCode]
		,[Amount]
		--,period_date_int  --39
		,[_company] --29
	from	
		(
		select 
			 [keyTransactionDate]
			,[Transaction Type]
			,'MA10008' [keyGLAccountNo]
			,[keyDimensionSetID]
			,[keyCountryCode]
			,[Amount]
			,[_company] --29
		from	
			[ext].[ChartOfAccounts]
		where
			[Management Heading] = 'Other Income and Expenses'
		and [Transaction Type] in ('Budget','Forecast') --39
	) coa
	--39
	/*cross apply
	(
	select
		 period_date_int
		,gl
	from
		@table_ChartOfAccounts t
	where
		gl = 'MA10008'
	) t
where
	[keyTransactionDate] = t.[period_date_int]*/
	) a
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading] [Management Heading]
    ,ma.[Management Category] [Management Category]
    ,isnull(ma.[Heading Sort],0) [Heading Sort]
    ,isnull(ma.[Category Sort],0) [Category Sort]
    ,isnull(ma.[main],0) [main]
    ,isnull(ma.[invert],0)  [invert]
    ,isnull(ma.[ma],0) [ma]
    ,ma.[Channel Category] [Channel Category]
    ,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
    ,sum(case when ma.invert = 1 then -x.[Amount] else x.[Amount] end) [Amount]
	,x.[_company] --29
from
    x
left join
    [ext].[ManagementAccounts] ma
on 
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
     x.[keyTransactionDate]
    ,x.[Transaction Type]
    ,x.[keyGLAccountNo]
    ,x.[keyDimensionSetID]
    ,x.[keyCountryCode]
    ,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company] --29


--budget & forecast units sold & order count
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --33
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,x.[Amount]
	,x.[_company] --33
from
	[ext].[Budget&Forecast] x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--ACTUAL UNITS SOLD
--UK
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,'Actual' [Transaction Type]
	,'MA10000' [keyGLAccountNo]
	,[Dimension Set ID] [keyDimensionSetID]
	,[Country_Region Code] [keyCountryCode]
	,-[Invoiced Quantity] [Invoiced Quantity]
from
	(
	select 
		 [Posting Date]
		,[Dimension Set ID]
		,[Invoiced Quantity]
		,[Country_Region Code]
		,period_date_int
	from	
		[dbo].[UK$Item Ledger Entry] 
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10000'
	) t
on
	(
		-- eomonth([Posting Date]) = t.period_eom --55
        [Posting Date] >= t.period_fom
    and [Posting Date] <= t.period_eom
	)
where
--	[Posting Date] >= t.period_fom
--and [Posting Date] <= t.period_eom
--and 
	[Entry Type] = 1
and patindex('ZZ%',[Item No_]) = 0 
and [Global Dimension 2 Code] <> '110' --53
	) ile
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,coalesce(nullif(x.[keyCountryCode],''),'ZZ') [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(x.[Invoiced Quantity]) [Amount]
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]


--ACTUAL UNITS SOLD
--NL--27
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,'Actual' [Transaction Type]
	,'MA10000' [keyGLAccountNo]
	,40000 + [Dimension Set ID] [keyDimensionSetID] --29
	,[Country_Region Code] [keyCountryCode]
	,-[Invoiced Quantity] [Invoiced Quantity]
	,4 [_company] --29
from
	(
	select 
		 [Posting Date]
		,[Dimension Set ID]
		,[Invoiced Quantity]
		,[Country_Region Code]
		,period_date_int
	from	
		[dbo].[NL$Item Ledger Entry] 
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10000'
	) t
on
	(
		-- eomonth([Posting Date]) = t.period_eom --55
        [Posting Date] >= t.period_fom
    and [Posting Date] <= t.period_eom
	)
where
--	[Posting Date] >= t.period_fom
--and [Posting Date] <= t.period_eom
--and 
	[Entry Type] = 1
and patindex('ZZ%',[Item No_]) = 0 
	) ile
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,coalesce(nullif(x.[keyCountryCode],''),'ZZ') [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(x.[Invoiced Quantity]) [Amount]
	,x.[_company] --29
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company] --29

--ACTUAL UNITS SOLD
--HSNZ--35
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,'Actual' [Transaction Type]
	,'MA10000' [keyGLAccountNo]
	,50000 + [Dimension Set ID] [keyDimensionSetID] 
	,[Country_Region Code] [keyCountryCode]
	,-[Invoiced Quantity] [Invoiced Quantity]
	,5 [_company] 
from
	(
	select 
		 [Posting Date]
		,[Dimension Set ID]
		,[Invoiced Quantity]
		,[Country_Region Code]
		,period_date_int
	from	
		[dbo].[NZ$Item Ledger Entry] 
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10000'
	) t
on
	(
		-- eomonth([Posting Date]) = t.period_eom --55
        [Posting Date] >= t.period_fom
    and [Posting Date] <= t.period_eom
	)
where
--	[Posting Date] >= t.period_fom
--and [Posting Date] <= t.period_eom
--and 
	[Entry Type] = 1
and patindex('ZZ%',[Item No_]) = 0 
	) ile
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,coalesce(nullif(x.[keyCountryCode],''),'ZZ') [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(x.[Invoiced Quantity]) [Amount]
	,x.[_company] 
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company] 



--ACTUAL UNITS SOLD
--HSIE--40
; with x as
(
select
	 period_date_int [keyTransactionDate] 
	,'Actual' [Transaction Type]
	,'MA10000' [keyGLAccountNo]
	,60000 + [Dimension Set ID] [keyDimensionSetID] 
	,isnull([Country_Region Code],'ZZ') [keyCountryCode] --43
	,-[Invoiced Quantity] [Invoiced Quantity]
	,6 [_company] 
from
	(
	select 
		 [Posting Date]
		,[Dimension Set ID]
		,[Invoiced Quantity]
		,[Country_Region Code]
		,period_date_int
	from	
		[dbo].[IE$Item Ledger Entry] 
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10000'
	) t
on
	(
		-- eomonth([Posting Date]) = t.period_eom --55
        [Posting Date] >= t.period_fom
    and [Posting Date] <= t.period_eom
	)
where
--	[Posting Date] >= t.period_fom
--and [Posting Date] <= t.period_eom
--and 
	[Entry Type] = 1
and patindex('ZZ%',[Item No_]) = 0 
	) ile
)

insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,coalesce(nullif(x.[keyCountryCode],''),'ZZ') [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,sum(x.[Invoiced Quantity]) [Amount]
	,x.[_company] 
from
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]
group by
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode]
	,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
	,x.[_company] 

--30
--ACTUAL -- ORDER COUNT BY REPORTING RANGE
--UK
; with x0 as
(
select
	 sih.period_date_int [keyTransactionDate]
	,'Actual' [Transaction Type]
	,'MA10001' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,sih.[Ship-to Country_Region Code] [keyCountryCode]
	,d.[_company] 
	,count(distinct(sih.[Order No_])) orderCount
from
	(
	select
		 [Ship-to Country_Region Code]
		,[Order No_]
		,[No_]
		,[Posting Date]
		,t.period_date_int
	from	
		[dbo].[UK$Sales Invoice Header] 
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10001'
	) t
on
	(
	  -- eomonth([Posting Date]) = t.period_eom --53 replaced with below for optimization
        [Posting Date] >= t.period_fom 
    and [Posting Date] <= t.period_eom
	)
where
--	[Posting Date] >= t.period_fom
--and [Posting Date] <= t.period_eom
--and 
	len([Order No_]) > 0
	) sih
join
	(
	select [Document No_],rr.[Reporting Range] from [dbo].[Sales_Invoice_Line] sil join [ext].[MA_Reporting_Range] rr on rr.[keyLegalEntity] = sil.[Shortcut Dimension 1 Code] and rr.[keyReportingGroup] = sil.[Shortcut Dimension 2 Code] where /* --53 abs([Quantity]) > 0 and*/ patindex('ZZ%', [No_]) = 0 group by [Document No_],rr.[Reporting Range]
	) sil
on
	sih.[No_] = sil.[Document No_]
left join --19
	(
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	(
	d.[Reporting Range] = sil.[Reporting Range]
	)
group by
	sih.period_date_int 
	,d.[keyDimensionSetID]
	,sih.[Ship-to Country_Region Code] 
	,d.[_company] --29
)

--ACTUAL -- ORDER COUNT BY REPORTING RANGE
--NL
,x1 as
(
select
	 sih.period_date_int [keyTransactionDate]
	,'Actual' [Transaction Type]
	,'MA10001' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,sih.[Ship-to Country_Region Code] [keyCountryCode]
	,count(distinct(sih.[Order No_])) orderCount
	,d.[_company] --29
from
	(
	select
		 [Ship-to Country_Region Code]
		,[Order No_]
		,[No_]
		,[Posting Date]
		,t.period_date_int
	from	
		[dbo].[NL$Sales Invoice Header] 
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10001'
	) t
on
	(
		-- eomonth([Posting Date]) = t.period_eom --53 replaced with below for optimization
        [Posting Date] >= t.period_fom 
    and [Posting Date] <= t.period_eom
	)
where
--	[Posting Date] >= t.period_fom
--and [Posting Date] <= t.period_eom
--and 
	len([Order No_]) > 0
	) sih
join
	(
	select [Document No_],rr.[Reporting Range] from [dbo].[NL$Sales Invoice Line]  sil join [ext].[MA_Reporting_Range] rr on rr.[keyLegalEntity] = sil.[Shortcut Dimension 1 Code] and rr.[keyReportingGroup] = sil.[Shortcut Dimension 2 Code] where abs([Quantity]) > 0 and patindex('ZZ%', [No_]) = 0 group by [Document No_],rr.[Reporting Range]
	) sil
	on
	sih.[No_] = sil.[Document No_]
left join --19
	(
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	(
	d.[Reporting Range] = sil.[Reporting Range]
	)
group by
	sih.period_date_int 
	,d.[keyDimensionSetID]
	,sih.[Ship-to Country_Region Code] 
	,d.[_company] --29
)

--ACTUAL -- ORDER COUNT BY REPORTING RANGE
--HSNZ --35
,x2 as
(
select
	 sih.period_date_int [keyTransactionDate]
	,'Actual' [Transaction Type]
	,'MA10001' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,sih.[Ship-to Country_Region Code] [keyCountryCode]
	,count(distinct(sih.[Order No_])) orderCount
	,d.[_company] 
from
	(
	select
		 [Ship-to Country_Region Code]
		,[Order No_]
		,[No_]
		,[Posting Date]
		,t.period_date_int
	from	
		[dbo].[NZ$Sales Invoice Header] 
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10001'
	) t
on
	(
		-- eomonth([Posting Date]) = t.period_eom --53 replaced with below for optimization
        [Posting Date] >= t.period_fom 
    and [Posting Date] <= t.period_eom
	)
where
--	[Posting Date] >= t.period_fom
--and [Posting Date] <= t.period_eom
--and 
	len([Order No_]) > 0
	) sih
join
	(
	select [Document No_],rr.[Reporting Range] from [dbo].[NZ$Sales Invoice Line]  sil join [ext].[MA_Reporting_Range] rr on rr.[keyLegalEntity] = sil.[Shortcut Dimension 1 Code] and rr.[keyReportingGroup] = sil.[Shortcut Dimension 2 Code] where abs([Quantity]) > 0 and patindex('ZZ%', [No_]) = 0 group by [Document No_],rr.[Reporting Range]
	) sil
	on
	sih.[No_] = sil.[Document No_]
left join
	(
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	(
	d.[Reporting Range] = sil.[Reporting Range]
	)
group by
	sih.period_date_int 
	,d.[keyDimensionSetID]
	,sih.[Ship-to Country_Region Code] 
	,d.[_company] --29
)


--ACTUAL -- ORDER COUNT BY REPORTING RANGE
--HSIE --40
,x3 as
(
select
	 sih.period_date_int [keyTransactionDate]
	,'Actual' [Transaction Type]
	,'MA10001' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,isnull(sih.[Ship-to Country_Region Code],'ZZ') [keyCountryCode] --43
	,count(distinct(sih.[Order No_])) orderCount
	,d.[_company] 
from
	(
	select
		 [Ship-to Country_Region Code]
		,[Order No_]
		,[No_]
		,[Posting Date]
		,t.period_date_int
	from	
		[dbo].[IE$Sales Invoice Header] 
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10001'
	) t
on
	(
		-- eomonth([Posting Date]) = t.period_eom --53 replaced with below for optimization
        [Posting Date] >= t.period_fom 
    and [Posting Date] <= t.period_eom
	)
where
--	[Posting Date] >= t.period_fom
--and [Posting Date] <= t.period_eom
--and 
	len([Order No_]) > 0
	) sih
join
	(
	select [Document No_],rr.[Reporting Range] from [dbo].[IE$Sales Invoice Line]  sil join [ext].[MA_Reporting_Range] rr on rr.[keyLegalEntity] = sil.[Shortcut Dimension 1 Code] and rr.[keyReportingGroup] = sil.[Shortcut Dimension 2 Code] where abs([Quantity]) > 0 and patindex('ZZ%', [No_]) = 0 group by [Document No_],rr.[Reporting Range]
	) sil
	on
	sih.[No_] = sil.[Document No_]
left join
	(
	select 
		 [Reporting Range]
		,min([_company]) [_company] 
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	(
	d.[Reporting Range] = sil.[Reporting Range]
	)
group by
	 sih.period_date_int 
	,d.[keyDimensionSetID]
	,sih.[Ship-to Country_Region Code] 
	,d.[_company] 
)


--one insert for UK, NL, HSNZ & HSIE companies
insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[_company],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount]) 
select
	 w.[keyTransactionDate]
	,w.[Transaction Type]
	,w.[keyGLAccountNo]
	,w.[keyDimensionSetID]
	,w.[_company]
	,w.[keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,w.[Amount]
from
		(
		select
			 coalesce(x0.[keyTransactionDate],x1.[keyTransactionDate],x2.[keyTransactionDate],x3.[keyTransactionDate]) [keyTransactionDate] --35 --40
			,coalesce(x0.[Transaction Type],x1.[Transaction Type],x2.[Transaction Type],x3.[Transaction Type]) [Transaction Type] --35 --40
			,coalesce(x0.[keyGLAccountNo],x1.[keyGLAccountNo],x2.[keyGLAccountNo],x3.[keyGLAccountNo]) [keyGLAccountNo] --35 --40
			,coalesce(x0.[keyDimensionSetID],x1.[keyDimensionSetID],x2.[keyDimensionSetID],x3.[keyDimensionSetID]) [keyDimensionSetID] --35 --40
			,coalesce(x0.[_company],x1.[_company],x2.[_company],x3.[_company]) [_company] --35 --40
			,coalesce(nullif(x0.[keyCountryCode],''),nullif(x1.[keyCountryCode],''),nullif(x2.[keyCountryCode],''),nullif(x3.[keyCountryCode],''),'ZZ') [keyCountryCode] --35 --40
			,isnull(x0.orderCount,0) + isnull(x1.orderCount,0) + isnull(x2.orderCount,0) + isnull(x3.orderCount,0) [Amount] --35 --40
		from
			x0
		full outer join
			x1
		on
			(
			x0.[keyTransactionDate] = x1.[keyTransactionDate]
		and x0.[Transaction Type] = x1.[Transaction Type]
		and x0.[keyGLAccountNo] = x1.[keyGLAccountNo]
		and x0.[keyDimensionSetID] = x1.[keyDimensionSetID]
		and x0.[_company] = x1.[_company]
		and x0.[keyCountryCode] = x1.[keyCountryCode]
			)
		full outer join --35
			x2
		on
			(
			isnull(x0.[keyTransactionDate],x1.[keyTransactionDate]) = x2.[keyTransactionDate]
		and isnull(x0.[Transaction Type],x1.[Transaction Type]) = x2.[Transaction Type]
		and isnull(x0.[keyGLAccountNo],x1.[keyGLAccountNo]) = x2.[keyGLAccountNo]
		and isnull(x0.[keyDimensionSetID],x1.[keyDimensionSetID]) = x2.[keyDimensionSetID]
		and isnull(x0.[_company],x1.[_company]) = x2.[_company]
		and isnull(x0.[keyCountryCode],x1.[keyCountryCode])  = x2.[keyCountryCode]
			)
		full outer join --40
			x3
		on
			(
			isnull(x0.[keyTransactionDate],x1.[keyTransactionDate]) = x3.[keyTransactionDate]
		and isnull(x0.[Transaction Type],x1.[Transaction Type]) = x3.[Transaction Type]
		and isnull(x0.[keyGLAccountNo],x1.[keyGLAccountNo]) = x3.[keyGLAccountNo]
		and isnull(x0.[keyDimensionSetID],x1.[keyDimensionSetID]) = x3.[keyDimensionSetID]
		and isnull(x0.[_company],x1.[_company]) = x3.[_company]
		and isnull(x0.[keyCountryCode],x1.[keyCountryCode])  = x3.[keyCountryCode]
			)
		) w --35
left join
	[ext].[ManagementAccounts] ma
on
	w.[keyGLAccountNo] = ma.[keyAccountCode] --35


--ACTUAL ORDER COUNT BY SALES CHANNEL
--UK
;with x as
(
select
	--  si.[Order No_] --56
	-- ,si.[Dimension Set ID] --56
	 sih.[Order No_] --56
	,sil.[Dimension Set ID] --56
	-- ,si.[Sale Channel] --56
    ,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --56
	-- ,si.period_date_int --56
    ,t.period_date_int --56
	-- ,si.[keyCountryCode] --56
    ,sih.[Ship-to Country_Region Code] [keyCountryCode] --56
from
	/* --56
	(select 
		  sih.[Order No_]
		 ,sil.[Dimension Set ID]
		 ,t.period_date_int
		 ,sih.[Ship-to Country_Region Code] [keyCountryCode]
	--,case --34
			--when sih.[Ship-to Country_Region Code] not in ('GB','GG','JE','IM') and (d.[Sale Channel] <> 'Intercompany' or  d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and sih.[Ship-to Country_Region Code] in ('GB','GG','JE','IM')) then 'Direct To Consumer'
		--	else d.[Sale Channel] --34
		--end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
	from
	*/ --56
	[dbo].[UK$Sales Invoice Line] sil 
join
	[dbo].[UK$Sales Invoice Header] sih
on
	sil.[Document No_] = sih.[No_]
left join
	[finance].[MA_Dimensions] d --19
on
	d.[keyDimensionSetID] = sil.[Dimension Set ID]
--cross apply --45
join
	(
	select
		[period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10001'
	) t
	on
		(
			-- eomonth(sih.[Posting Date]) = t.period_eom --53 replaced with below for optimization
			sih.[Posting Date] >= t.period_fom 
		and sih.[Posting Date] <= t.period_eom
		)
where
--	sih.[Posting Date] >= t.period_fom 
--and sih.[Posting Date] <= t.period_eom
--and 
	-- abs([Quantity]) > 0 --53
-- and 
	patindex('ZZ%', sil.[No_]) = 0
and len(sih.[Order No_]) > 0
and sil.[Shortcut Dimension 2 Code] <> '110' --53
	-- ) si --56
)

,y as
(
select 
	 x.period_date_int [keyTransactionDate]
	--  ,'Actual' [Transaction Type] --56
	--  ,'MA10001' [keyGLAccountNo] --56
	,x.[keyCountryCode]
	,d.[Sale Channel]
	-- ,d.[keyDimensionSetID] --56
	,isnull(d.[keyDimensionSetID],20) [keyDimensionSetID] --56
	,x.[Order No_]
from
		x
left join
	(--19
	select 
		 [Sale Channel]
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Sale Channel] is not null
	group by
		 [Sale Channel]
	) d
on 
	d.[Sale Channel] = x.[Sale Channel]
)


insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 y.[keyTransactionDate]
	-- ,y.[Transaction Type] --56
	-- ,y.[keyGLAccountNo] --56
    ,'Actual' [Transaction Type] --56
	,'MA10001' [keyGLAccountNo] --56
	--,case --20 & 34
		--when y.[keyDimensionSetID] is null and y.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when y.[keyDimensionSetID] is null and y.[keyCountryCode] not in ('GB','GG','JE','IM') and (y.[Sale Channel] <> 'Intercompany' or y.[Sale Channel] is null) then 23 --34
		--else y.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	-- ,isnull(y.[keyDimensionSetID],20) [keyDimensionSetID] --34 --56
	,y.[keyDimensionSetID] --56
	-- ,coalesce(nullif(y.[keyCountryCode],''),'ZZ') [keyCountryCode] --56
	,isnull(nullif(y.[keyCountryCode],''),'ZZ') [keyCountryCode] --56
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,count(distinct(y.[Order No_])) [Amount]
	,1 [_company] --29
from
	y
left join
	[ext].[ManagementAccounts] ma
on
	-- y.[keyGLAccountNo] = ma.[keyAccountCode] --56
    ma.[keyAccountCode] = 'MA10001'
group by
	 y.[keyTransactionDate]
	-- ,y.[Transaction Type] --56
	-- ,y.[keyGLAccountNo] --56
	--,case --20 & 34
		--when y.[keyDimensionSetID] is null and y.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when y.[keyDimensionSetID] is null and y.[keyCountryCode] not in ('GB','GG','JE','IM') and (y.[Sale Channel] <> 'Intercompany' or y.[Sale Channel] is null) then 23 --34
		--else y.[keyDimensionSetID] --34
	 --end --34
	-- ,isnull(y.[keyDimensionSetID],20) --34 --56
	,y.[keyDimensionSetID] --56
	,y.[keyCountryCode]
	,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]


--ACTUAL ORDER COUNT BY SALES CHANNEL
--NL--28
;with x as
(
select
	 --  si.[Order No_] --56
	-- ,si.[Dimension Set ID] --56
	 sih.[Order No_] --56
	,sil.[Dimension Set ID] --56
	-- ,si.[Sale Channel] --56
    ,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --56
	-- ,si.period_date_int --56
    ,t.period_date_int --56
	-- ,si.[keyCountryCode] --56
    ,sih.[Ship-to Country_Region Code] [keyCountryCode] --56
from
	/* --56
	(select 
		  sih.[Order No_]
		 ,sil.[Dimension Set ID]
		 ,t.period_date_int
		 ,sih.[Ship-to Country_Region Code] [keyCountryCode]
	--,case --34
			--when sih.[Ship-to Country_Region Code] not in ('GB','GG','JE','IM') and (d.[Sale Channel] <> 'Intercompany' or  d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and sih.[Ship-to Country_Region Code] in ('GB','GG','JE','IM')) then 'Direct To Consumer'
		--	else d.[Sale Channel] --34
		--end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
	from
	*/ --56
		[dbo].[NL$Sales Invoice Line] sil 
	join
		[dbo].[NL$Sales Invoice Header] sih
	on
		sil.[Document No_] = sih.[No_]
	left join
		[finance].[MA_Dimensions] d --19
	on
		d.[keyDimensionSetID] = sil.[Dimension Set ID]
	--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10001'
	) t
	on
		(
			-- eomonth(sih.[Posting Date]) = t.period_eom --53 replaced with below for efficiency
            sih.[Posting Date] >= t.period_fom 
        and sih.[Posting Date] <= t.period_eom
		)
	where
--	sih.[Posting Date] >= t.period_fom 
--and sih.[Posting Date] <= t.period_eom
--and 
	-- abs([Quantity]) > 0 --53
-- and 
    patindex('ZZ%', sil.[No_]) = 0
and len(sih.[Order No_]) > 0
-- ) si --56
)

,y as
(
select 
	 x.period_date_int [keyTransactionDate]
	--  ,'Actual' [Transaction Type] --56
	--  ,'MA10001' [keyGLAccountNo] --56
	,x.[keyCountryCode]
	,d.[Sale Channel]
	-- ,d.[keyDimensionSetID] --56
	,isnull(d.[keyDimensionSetID],20) [keyDimensionSetID] --56
	,x.[Order No_]
from
	x
left join
		(--19
	select 
		 [Sale Channel]
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Sale Channel] is not null
	group by
		[Sale Channel]
	) d
on 
	d.[Sale Channel] = x.[Sale Channel]
)


insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
	 y.[keyTransactionDate]
	-- ,y.[Transaction Type] --56
	-- ,y.[keyGLAccountNo] --56
    ,'Actual' [Transaction Type] --56
	,'MA10001' [keyGLAccountNo] --56
	--,case --20 & 34
		--when y.[keyDimensionSetID] is null and y.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when y.[keyDimensionSetID] is null and y.[keyCountryCode] not in ('GB','GG','JE','IM') and (y.[Sale Channel] <> 'Intercompany' or y.[Sale Channel] is null) then 23 --34
		--else y.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	-- ,isnull(y.[keyDimensionSetID],20) [keyDimensionSetID] --34 --56
	,y.[keyDimensionSetID] --56
	-- ,coalesce(nullif(y.[keyCountryCode],''),'ZZ') [keyCountryCode] --56
	,isnull(nullif(y.[keyCountryCode],''),'ZZ') [keyCountryCode] --56
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,count(distinct(y.[Order No_])) [Amount]
	,4 [_company] --29
from
	y
left join
	[ext].[ManagementAccounts] ma
on
	-- y.[keyGLAccountNo] = ma.[keyAccountCode] --56
    ma.[keyAccountCode] = 'MA10001'
group by
	 y.[keyTransactionDate]
	-- ,y.[Transaction Type] --56
	-- ,y.[keyGLAccountNo] --56
	--,case --20 & 34
		--when y.[keyDimensionSetID] is null and y.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when y.[keyDimensionSetID] is null and y.[keyCountryCode] not in ('GB','GG','JE','IM') and (y.[Sale Channel] <> 'Intercompany' or y.[Sale Channel] is null) then 23 --34
		--else y.[keyDimensionSetID] --34
	 --end --34
	-- ,isnull(y.[keyDimensionSetID],20) --34 --56
	,y.[keyDimensionSetID] --56
	,y.[keyCountryCode]
	,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]


--ACTUAL ORDER COUNT BY SALES CHANNEL
--HSNZ--35
;with x as
(
select
	--  si.[Order No_] --56
	-- ,si.[Dimension Set ID] --56
	 sih.[Order No_] --56
	,sil.[Dimension Set ID] --56
	-- ,si.[Sale Channel] --56
    ,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --56
	-- ,si.period_date_int --56
    ,t.period_date_int --56
	-- ,si.[keyCountryCode] --56
    ,sih.[Ship-to Country_Region Code] [keyCountryCode] --56
from
	/* --56
	(select 
		  sih.[Order No_]
		 ,sil.[Dimension Set ID]
		 ,t.period_date_int
		 ,sih.[Ship-to Country_Region Code] [keyCountryCode]
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] 
	from
	*/ --56
	[dbo].[NZ$Sales Invoice Line] sil 
join
	[dbo].[NZ$Sales Invoice Header] sih
on
	sil.[Document No_] = sih.[No_]
left join
	[finance].[MA_Dimensions] d 
on
	d.[keyDimensionSetID] = sil.[Dimension Set ID]
--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10001'
	) t
	on
		(
			-- eomonth(sih.[Posting Date]) = t.period_eom --53 replaced with below for efficiency
            sih.[Posting Date] >= t.period_fom 
        and sih.[Posting Date] <= t.period_eom
		)
where
--	sih.[Posting Date] >= t.period_fom 
--and sih.[Posting Date] <= t.period_eom
--and 
	-- abs([Quantity]) > 0 --53
-- and 
    patindex('ZZ%', sil.[No_]) = 0
and len(sih.[Order No_]) > 0
	-- ) si --56
)

,y as
(
select 
	 x.period_date_int [keyTransactionDate]
	--  ,'Actual' [Transaction Type] --56
	--  ,'MA10001' [keyGLAccountNo] --56
	,x.[keyCountryCode]
	,d.[Sale Channel]
	-- ,d.[keyDimensionSetID] --56
	,isnull(d.[keyDimensionSetID],20) [keyDimensionSetID] --56
	,x.[Order No_]
from
		x
left join
		(
	select 
		 [Sale Channel]
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Sale Channel] is not null
	group by
		[Sale Channel]
	) d
on 
	d.[Sale Channel] = x.[Sale Channel]
)


insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
	 y.[keyTransactionDate]
	-- ,y.[Transaction Type] --56
	-- ,y.[keyGLAccountNo] --56
    ,'Actual' [Transaction Type] --56
	,'MA10001' [keyGLAccountNo] --56
	,isnull(y.[keyDimensionSetID],20) [keyDimensionSetID] 
	,coalesce(nullif(y.[keyCountryCode],''),'ZZ') [keyCountryCode]
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,count(distinct(y.[Order No_])) [Amount]
	,5 [_company] 
from
	y
left join
	[ext].[ManagementAccounts] ma
on
	-- y.[keyGLAccountNo] = ma.[keyAccountCode] --56
    ma.[keyAccountCode] = 'MA10001'
group by
	 y.[keyTransactionDate]
	-- ,y.[Transaction Type] --56
	-- ,y.[keyGLAccountNo] --56
	-- ,isnull(y.[keyDimensionSetID],20) --34 --56
	,y.[keyDimensionSetID] --56
	,y.[keyCountryCode]
	,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]


--ACTUAL ORDER COUNT BY SALES CHANNEL
--HSIE--40
;with x as
(select
	 --  si.[Order No_] --56
	-- ,si.[Dimension Set ID] --56
	 sih.[Order No_] --56
	,sil.[Dimension Set ID] --56
	-- ,si.[Sale Channel] --56
    ,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --56
	-- ,si.period_date_int --56
    ,t.period_date_int --56
	-- ,isnull(si.[keyCountryCode],'ZZ') [keyCountryCode] --43 --56
	,sih.[Ship-to Country_Region Code] [keyCountryCode] --56
from
	/* --56
	(select 
		  sih.[Order No_]
		 ,sil.[Dimension Set ID]
		 ,t.period_date_int
		 ,sih.[Ship-to Country_Region Code] [keyCountryCode]
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] 
	from
	*/ --56
	[dbo].[IE$Sales Invoice Line] sil 
join
	[dbo].[IE$Sales Invoice Header] sih
on
	sil.[Document No_] = sih.[No_]
left join
	[finance].[MA_Dimensions] d 
on
	d.[keyDimensionSetID] = sil.[Dimension Set ID]
--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10001'
	) t
	on
		(
			-- eomonth(sih.[Posting Date]) = t.period_eom --53 replaced with below for efficiency
            sih.[Posting Date] >= t.period_fom 
        and sih.[Posting Date] <= t.period_eom
		)
	where
--	sih.[Posting Date] >= t.period_fom 
--and sih.[Posting Date] <= t.period_eom
--and 
	-- abs([Quantity]) > 0 --53
-- and 
    patindex('ZZ%', sil.[No_]) = 0
and len(sih.[Order No_]) > 0
	-- ) si --56
)

,y as
(
select 
	 x.period_date_int [keyTransactionDate]
	--  ,'Actual' [Transaction Type] --56
	--  ,'MA10001' [keyGLAccountNo] --56
	,x.[keyCountryCode]
	,d.[Sale Channel]
	-- ,d.[keyDimensionSetID] --56
	,isnull(d.[keyDimensionSetID],20) [keyDimensionSetID] --56
	,x.[Order No_]
from
		x
left join
		(
	select 
		 [Sale Channel]
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Sale Channel] is not null
	group by
		[Sale Channel]
	) d
on 
	d.[Sale Channel] = x.[Sale Channel]
)


insert into ext.ChartOfAccounts ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
	 y.[keyTransactionDate]
	-- ,y.[Transaction Type] --56
	-- ,y.[keyGLAccountNo] --56
    ,'Actual' [Transaction Type] --56
	,'MA10001' [keyGLAccountNo] --56
	-- ,isnull(y.[keyDimensionSetID],20) [keyDimensionSetID] --56
	,y.[keyDimensionSetID] --56
	-- ,coalesce(nullif(y.[keyCountryCode],''),'ZZ') [keyCountryCode] --56
	,isnull(nullif(y.[keyCountryCode],''),'ZZ') [keyCountryCode] --56
	,ma.[Management Heading] [Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,count(distinct(y.[Order No_])) [Amount]
	,6 [_company] 
from
	y
left join
	[ext].[ManagementAccounts] ma
on
	-- y.[keyGLAccountNo] = ma.[keyAccountCode] --56
    ma.[keyAccountCode] = 'MA10001'
group by
	 y.[keyTransactionDate]
	-- ,y.[Transaction Type] --56
	-- ,y.[keyGLAccountNo] --56
	-- ,isnull(y.[keyDimensionSetID],20) --56
	,y.[keyDimensionSetID] --56
	,y.[keyCountryCode]
	,ma.[Management Heading]
    ,ma.[Management Category]
    ,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]

--AVERAGE ORDER VALUE BY REPORTING RANGE
--ACTUAL & FORECAST - Last Month This Year
; with x as
(
select
	 isnull(a.[keyTransactionDate],b.[keyTransactionDate]) [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,round(isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0),2) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	(--19 
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] < 20 /*8*/ and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10002'
	) t
on
	(
		isnull(a.[keyTransactionDate],b.[keyTransactionDate]) = t.period_date_int
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
--where
--	isnull(a.[keyTransactionDate],b.[keyTransactionDate]) = t.period_date_int
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,isnull(a.[keyTransactionDate],b.[keyTransactionDate])
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company])
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--AVERAGE ORDER VALUE BY REPORTING RANGE
--ACTUAL & FORECAST - YTD This Year
; with x as
(
select
	 0 [keyTransactionDate]
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,round(isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0),2) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	 	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] < 20 /* 8 */ and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]	
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]

--AVERAGE ORDER VALUE BY REPORTING RANGE
--ACTUAL - Last Month Last Year
;with x as
(
select
	 isnull(a.[keyTransactionDate],b.[keyTransactionDate]) [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,round(isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0),2) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	 	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] < 20 /* 8 */ and [Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,isnull(a.[keyTransactionDate],b.[keyTransactionDate])
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]

--AVERAGE ORDER VALUE BY REPORTING RANGE
--ACTUAL - YTD Last Year
; with x as
(
select
	 1 [keyTransactionDate]
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,round(isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0),2) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	 	(--19	
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] < 20 /* 8 */ and [Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]	
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--31 & 38 & 54 ACTUAL - YTD Last Year - NL
insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
values(1,'Actual','MA10002',8,'ZZ','Orders','Average Order Value',4,7,1,0,1,'',0,NULL,/*3*/4) --34

--31 ACTUAL - YTD Last Year - HSNZ --46
--insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
--values(1,'Actual','MA10002',10,'ZZ','Orders','Average Order Value',4,7,1,0,1,'',0,NULL,/*3*/5) --34

--54 ACTUAL - YTD This Year - HSNZ
insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
values(0,'Actual','MA10002',10,'ZZ','Orders','Average Order Value',4,7,1,0,1,'',0,NULL,/*3*/5)

/*43 - no longer needed; PK violation
--31 &--40 & --43 ACTUAL - YTD This Year - HSIE
insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
values(0,'Actual','MA10002',11,'ZZ','Orders','Average Order Value',4,7,1,0,1,'',0,0,/*3*/6) --34
*/

--31 &--40 &--46 &--47 & 49 ACTUAL - YTD Last Year - HSIE 
-- insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
-- values(1,'Actual','MA10002',11,'ZZ','Orders','Average Order Value',4,7,1,0,1,'',0,NULL,/*3*/6) --34

--50 ACTUAL - YTD This Year - NL
insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
values(0,'Actual','MA10002',8,'ZZ','Orders','Average Order Value',4,7,1,0,1,'',0,NULL,/*3*/4) 



--AVERAGE ORDER VALUE BY REPORTING RANGE
--ACTUAL - Full Year Last Year
; with x as
(
select
	 3 [keyTransactionDate]
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,round(isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0),2) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	 (--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] < 20 /* 8 */ and [Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]	
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]

--AVERAGE ORDER VALUE BY REPORTING RANGE
--BUDGET - Full Year This Year
; with x as
(
select
	 2 [keyTransactionDate]
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,round(isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0),2) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and c.[Transaction Type] in ('Budget') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] < 20 /* 8 */ and [Transaction Type] in ('Budget') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]	
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]

--AVERAGE ORDER VALUE BY REPORTING RANGE
--FORECAST - Full Year This Year
; with x as
(
select
	 2 [keyTransactionDate]
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,round(isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0),2) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and ((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))) or (c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	 	(--19	
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] < 20 /* 8 */ and ((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))) or (c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]	
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--AVERAGE ORDER VALUE BY SALE CHANNEL
--ACTUAL - Last Month This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34
			--when sih.[Ship-to Country_Region Code] not in ('GB','GG','JE','IM') and (d.[Sale Channel] <> 'Intercompany' or  d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and sih.[Ship-to Country_Region Code] in ('GB','GG','JE','IM')) then 'Direct To Consumer'
		--	else d.[Sale Channel] --34
		--end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from
		ext.ChartOfAccounts c 
	left join
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
--cross apply --45
join
	(select 
		 [period_date]
		,period_fom, period_eom
		,period_date_int 
	from 
		@table_ChartOfAccounts 
	where gl = 'MA10002'
	) t 
on
	(
		az.[keyTransactionDate] = t.period_date_int
	)
--where
--	az.[keyTransactionDate] = t.period_date_int
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end --34
	,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] in (20,21,22,/*23,*/24,25) --19 & 34
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
		--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
--cross apply --45
join
	(select 
		[period_date]
		, period_fom, period_eom
		, period_date_int 
	from 
		@table_ChartOfAccounts 
	where 
		gl = 'MA10002'
	) t 
on
	(
		 z.[keyTransactionDate] = t.period_date_int
	)
--where
--	 z.[keyTransactionDate] = t.period_date_int
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,round(isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0),2) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--AVERAGE ORDER VALUE BY SALE CHANNEL
--ACTUAL & FORECAST - YTD This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 
,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)
,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] in (20,21,22/*,23*/,24,25) --19 & 34
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 
,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 0 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,round(isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0),2) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	

--AVERAGE ORDER VALUE BY SALE CHANNEL
--ACTUAL & FORECAST - Last Month Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 
,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] in (20,21,22/*,23*/,24,25) --19 & 34
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 
,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,round(isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0),2) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	

--AVERAGE ORDER VALUE BY SALE CHANNEL
--ACTUAL - YTD Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 
,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)
,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] in (20,21,22/*,23*/,24,25) --19 & 34
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 
,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 1 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,round(isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0),2) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
		ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	

--AVERAGE ORDER VALUE BY SALE CHANNEL
--ACTUAL - Full Year Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 
,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)
,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] in (20,21,22/*,23*/,24,25) --19 & 34
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 
,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 3 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,round(isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0),2) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	

/* No Budget Data Available
--AVERAGE ORDER VALUE BY SALE CHANNEL
--BUDGET - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,case when 
			c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') then 'International' 
			when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' 
		else d.[Sale Channel] end [Sale Channel]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Budget') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 
,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)
,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,case
		when (az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM','ZZ')) then 8
		when (az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM')) then 11
	else az.[keyDimensionSetID]
	end [keyDimensionSetID]
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,case
		when (az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM','ZZ')) then 8
		when (az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM')) then 11
	else az.[keyDimensionSetID]
	end 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,case when 
			c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') then 'International' 
			when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' 
		else d.[Sale Channel] end [Sale Channel]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] in (8,9,10,11,12) 
	and c.[Transaction Type] in ('Budget') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 
,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,case
		when (z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM','ZZ')) then 8
		when (z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM')) then 11
	else z.[keyDimensionSetID]
	end [keyDimensionSetID]
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,case
		when (z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM','ZZ')) then 8
		when (z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM')) then 11
	else z.[keyDimensionSetID]
	end 
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],0) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,round(isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0),2) [Amount]
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	
*/

/* No Forecast Data Available
--AVERAGE ORDER VALUE BY SALE CHANNEL
--FORECAST - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,case when 
			c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') then 'International' 
			when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' 
		else d.[Sale Channel] end [Sale Channel]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 
,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)
,aw as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,case
		when (az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM','ZZ')) then 8
		when (az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM')) then 11
	else az.[keyDimensionSetID]
	end [keyDimensionSetID]
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 case
		when (az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM','ZZ')) then 8
		when (az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM')) then 11
	else az.[keyDimensionSetID]
	end 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,case when 
			c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') then 'International' 
			when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' 
		else d.[Sale Channel] end [Sale Channel]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[keyGLAccountNo] = 'MA10001' and c.[keyDimensionSetID] in (8,9,10,11,12) 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 
,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,case
		when (z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM','ZZ')) then 8
		when (z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM')) then 11
	else z.[keyDimensionSetID]
	end [keyDimensionSetID]
	,sum(z.[Amount]) [Amount]
from
	z
group by
	case
		when (z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM','ZZ')) then 8
		when (z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM')) then 11
	else z.[keyDimensionSetID]
	end 
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount])
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10002' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],0) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,round(isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0),2) [Amount]
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]
*/

--GROSS MARGIN % BY REPORTING RANGE
--ACTUAL & FORECAST - Last Month This Year
; with x as
(
select
	 isnull(a.[keyTransactionDate],b.[keyTransactionDate]) [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Gross Margin' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	 (--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10003'
	) t
on
	(
		isnull(a.[keyTransactionDate],b.[keyTransactionDate]) = t.period_date_int
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
--where
--	isnull(a.[keyTransactionDate],b.[keyTransactionDate]) = t.period_date_int
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,isnull(a.[keyTransactionDate],b.[keyTransactionDate])
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--GROSS MARGIN % BY REPORTING RANGE
--ACTUAL & FORECAST - YTD This Year
; with x as
(
select
	 0 [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Gross Margin' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by [Transaction Type], d.[Reporting Range]
	) a
full join
	 (--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--GROSS MARGIN % BY REPORTING RANGE
--ACTUAL & FORECAST - Last Month Last Year
; with x as
(
select
	 isnull(a.[keyTransactionDate],b.[keyTransactionDate]) [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Gross Margin' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))  and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) a
full join
	(--19	
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))  and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,isnull(a.[keyTransactionDate],b.[keyTransactionDate])
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--GROSS MARGIN % BY REPORTING RANGE
--ACTUAL & FORECAST - YTD Last Year
; with x as
(
select
	 1 [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Gross Margin' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by [Transaction Type], d.[Reporting Range]
	) a
full join
	(--19	
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--GROSS MARGIN % BY REPORTING RANGE
--ACTUAL - Full Year Last Year
; with x as
(
select
	 3 [keyTransactionDate] 
	,'Actual' [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19	
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Gross Margin' and c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31) group by [Transaction Type], d.[Reporting Range]
	) a
full join
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31) group by [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]

--GROSS MARGIN % BY REPORTING RANGE
--BUDGET - Full Year This Year
; with x as
(
select
	 2 [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19	
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Gross Margin' and c.[Transaction Type] in ('Budget') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31) group by [Transaction Type], d.[Reporting Range]
	) a
full join
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Budget') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31) group by [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--GROSS MARGIN % BY REPORTING RANGE
--FORECAST - Full Year This Year - 
; with x as
(
select
	 2 [keyTransactionDate] 
	,'Forecast' [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Gross Margin' and ((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))) or (c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31))) group by d.[Reporting Range]
	) a
full join
	(--19
	select d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and ((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))) or (c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31))) group by d.[Reporting Range]
	) b
on
	(
		a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--GROSS MARGIN % BY SALE CHANNEL
--ACTUAL & FORECAST - Last Month This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
--cross apply --45
join
	(select 
		 [period_date]
		,period_fom, period_eom
		,period_date_int 
	from 
		@table_ChartOfAccounts 
	where gl = 'MA10003'
	) t 
on
	(
		az.[keyTransactionDate] = t.period_date_int
	)
--where
--	az.[keyTransactionDate] = t.period_date_int
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
		--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 
,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
--cross apply --45
join
	(select 
		[period_date]
		, period_fom, period_eom
		, period_date_int 
	from 
		@table_ChartOfAccounts 
	where 
		gl = 'MA10003'
	) t 
on
	(
		z.[keyTransactionDate] = t.period_date_int
	)
--where
--	 z.[keyTransactionDate] = t.period_date_int
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) --32
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--GROSS MARGIN % BY SALE CHANNEL
--ACTUAL & FORECAST - YTD This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 0 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) --32
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--GROSS MARGIN % BY SALE CHANNEL
--ACTUAL & FORECAST - Last Month Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) --32
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--GROSS MARGIN % BY SALE CHANNEL
--ACTUAL & FORECAST - YTD Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 
,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)
,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 
,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 1 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
		ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) --32
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--GROSS MARGIN % BY SALE CHANNEL
--ACTUAL - Full Year Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 
,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 3 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) --32
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	

--GROSS MARGIN % BY SALE CHANNEL
--BUDGET - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Budget') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Budget') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	--end --34
	,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) --32
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	

--GROSS MARGIN % BY SALE CHANNEL
--FORECAST - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Gross Margin' 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) --32
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]

--GROSS MARGIN % BY JURISDICTION --37
--ACTUAL & FORECAST - Last Month This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
--cross apply --45
join
	(select 
		 [period_date]
		,period_fom, period_eom
		,period_date_int 
	from 
		@table_ChartOfAccounts 
	where gl = 'MA10003'
	) t 
on
	(
		az.[keyTransactionDate] = t.period_date_int
	)
--where
--	az.[keyTransactionDate] = t.period_date_int
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
--cross apply --45
join
	(select 
		[period_date]
		, period_fom, period_eom
		, period_date_int 
	from 
		@table_ChartOfAccounts 
	where 
		gl = 'MA10003'
	) t 
on
	(
		 z.[keyTransactionDate] = t.period_date_int
	)
--where
--	 z.[keyTransactionDate] = t.period_date_int
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 ,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--GROSS MARGIN % BY JURISDICTION --37
--ACTUAL & FORECAST - YTD This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
/*
cross apply 
	(select 
		 [period_date]
		,period_fom, period_eom
		,period_date_int 
	from 
		@table_ChartOfAccounts 
	where gl = 'MA10003'
	) t 
where
	az.[keyTransactionDate] = t.period_date_int
*/
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
		and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 ,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 0 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--GROSS MARGIN % BY JURISDICTION --37
--ACTUAL & FORECAST - Last Month Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--GROSS MARGIN % BY JURISDICTION --37
--ACTUAL & FORECAST - YTD Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 1 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] 
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--GROSS MARGIN % BY JURISDICTION --37
--ACTUAL - Full Year Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 ,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 3 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--GROSS MARGIN % BY JURISDICTION --37
--BUDGET - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Gross Margin' 
	and c.[Transaction Type] in ('Budget')  
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in  ('Budget') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 ,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--GROSS MARGIN % BY JURISDICTION --37
--FORECAST - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Gross Margin' 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10003' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] 
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	

--CONTRIBUTION MARGIN (CM1) % BY REPORTING RANGE --42
--ACTUAL & FORECAST - Last Month This Year
;with x as
(
select
	 isnull(a.[keyTransactionDate],b.[keyTransactionDate]) [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10005' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Contribution Margin (CM1)' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range] --42
	) a
full join
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
--cross apply --45
join
	(
	select
		 [period_date]
		,period_fom	
		,period_eom	
		,period_date_int
	from
		@table_ChartOfAccounts 
	where
		gl = 'MA10005'
	) t
on
	(
		isnull(a.[keyTransactionDate],b.[keyTransactionDate]) = t.period_date_int
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
--where
--	isnull(a.[keyTransactionDate],b.[keyTransactionDate]) = t.period_date_int
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,isnull(a.[keyTransactionDate],b.[keyTransactionDate])
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--CONTRIBUTION MARGIN (CM1) % BY REPORTING RANGE --42
--ACTUAL & FORECAST - YTD This Year
; with x as
(
select
	 0 [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10005' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Contribution Margin (CM1)' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by [Transaction Type], d.[Reporting Range] --42
	) a
full join
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)) group by [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
	    ,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--CONTRIBUTION MARGIN (CM1) % BY REPORTING RANGE --42
--ACTUAL & FORECAST - Last Month Last Year
; with x as
(
select
	 isnull(a.[keyTransactionDate],b.[keyTransactionDate]) [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10005' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Contribution Margin (CM1)' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))  and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range] --42
	) a
full join
	(--19
	select c.[keyTransactionDate], c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))  and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by c.[keyTransactionDate], [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[keyTransactionDate] = b.[keyTransactionDate]
	and a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,isnull(a.[keyTransactionDate],b.[keyTransactionDate])
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--CONTRIBUTION MARGIN (CM1) % BY REPORTING RANGE --42
--ACTUAL & FORECAST - YTD Last Year
;with x as
(
select
	 1 [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10005' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Contribution Margin (CM1)' and c.[Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by [Transaction Type], d.[Reporting Range] --42
	) a
full join
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual','Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate))) group by [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--CONTRIBUTION MARGIN (CM1) % BY REPORTING RANGE --42
--ACTUAL - Full Year Last Year
; with x as
(
select
	 3 [keyTransactionDate] 
	,'Actual' [Transaction Type]
	,'MA10005' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Contribution Margin (CM1)' and c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31) group by [Transaction Type], d.[Reporting Range]
	) a
full join
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Actual') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31) group by [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
		select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--CONTRIBUTION MARGIN (CM1) % BY REPORTING RANGE --42
--BUDGET - Full Year This Year
; with x as
(
select
	 2 [keyTransactionDate] 
	,isnull(a.[Transaction Type],b.[Transaction Type]) [Transaction Type]
	,'MA10005' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Contribution Margin (CM1)' and c.[Transaction Type] in ('Budget') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31) group by [Transaction Type], d.[Reporting Range] --42
	) a
full join
	(--19	
	select c.[Transaction Type], d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and [Transaction Type] in ('Budget') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31) group by [Transaction Type], d.[Reporting Range]
	) b
on
	(
		a.[Transaction Type] = b.[Transaction Type]
	and a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Transaction Type],b.[Transaction Type]) 
	,isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--CONTRIBUTION MARGIN (CM1) % BY REPORTING RANGE --42
--FORECAST - Full Year This Year 
; with x as
(
select
	 2 [keyTransactionDate] 
	,'Forecast' [Transaction Type]
	,'MA10005' [keyGLAccountNo]
	,d.[keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,isnull(sum(a.[Amount]),0)/nullif(isnull(sum(b.[Amount]),0),0) [Amount]
	,d.[_company] --29
from
	(--19	
	select d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Contribution Margin (CM1)' and ((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))) or (c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31))) group by d.[Reporting Range] --42
	) a
full join
	(--19
	select d.[Reporting Range], sum(c.[Amount]) [Amount] from ext.ChartOfAccounts c join [finance].[MA_Dimensions] d on c.[keyDimensionSetID] = d.keyDimensionSetID where c.[Management Heading] = 'Net Sales' and ((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))) or (c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31))) group by d.[Reporting Range]
	) b
on
	(
		a.[Reporting Range] = b.[Reporting Range]
	)
join
	(--19
	select 
		 [Reporting Range]
		,min([_company]) [_company] --29
		,min([keyDimensionSetID]) [keyDimensionSetID]	
	from 
		[finance].[MA_Dimensions]  
	where 
		[Reporting Range] is not null
	and [Reporting Range] not in ('Group Eliminations','HSGY Eliminations')
	group by
		[Reporting Range]
	) d
on 
	d.[Reporting Range] = isnull(a.[Reporting Range],b.[Reporting Range])
group by
	 isnull(a.[Reporting Range],b.[Reporting Range]) 
	,d.[keyDimensionSetID]
	,d.[_company] --29
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 x.[keyTransactionDate]
	,x.[Transaction Type]
	,x.[keyGLAccountNo]
	,x.[keyDimensionSetID]
	,x.[keyCountryCode] 
	,ma.[Management Heading] 
	,ma.[Management Category] 
	,ma.[Heading Sort]
	,ma.[Category Sort] 
	,ma.[main] 
	,ma.[invert]
	,ma.[ma]
	,ma.[Channel Category] 
	,ma.[Channel Sort]
	,x.[Amount]
	,x.[_company] --29
from 
	x
left join
	[ext].[ManagementAccounts] ma
on
	x.[keyGLAccountNo] = ma.[keyAccountCode]


--EBITDA % OF NET SALES BY SALE CHANNEL
--ACTUAL & FORECAST - Last Month This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'EBITDA' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <=  eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
--cross apply --45
join
	(select 
		 [period_date]
		,period_fom, period_eom
		,period_date_int 
	from 
		@table_ChartOfAccounts 
	where gl = 'MA10007'
	) t 
on
	(
		az.[keyTransactionDate] = t.period_date_int
	)
--where
--	az.[keyTransactionDate] = t.period_date_int
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
--cross apply --45
join
	(select 
		[period_date]
		, period_fom, period_eom
		, period_date_int 
	from 
		@table_ChartOfAccounts 
	where 
		gl = 'MA10007'
	) t 
on
	(
		 z.[keyTransactionDate] = t.period_date_int
	)
--where
--	 z.[keyTransactionDate] = t.period_date_int
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]			


--EBITDA % OF NET SALES BY SALE CHANNEL
--ACTUAL & FORECAST - YTD This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'EBITDA' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 0 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--EBITDA % OF NET SALES BY SALE CHANNEL
--ACTUAL & FORECAST - Last Month Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'EBITDA' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--EBITDA % OF NET SALES BY SALE CHANNEL
--ACTUAL & FORECAST - YTD Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'EBITDA' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 1 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--EBITDA % OF NET SALES BY SALE CHANNEL
--ACTUAL - Full Year Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'EBITDA' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	 ,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	--,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 3 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--EBITDA % OF NET SALES BY SALE CHANNEL
--BUDGET - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
				from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'EBITDA' 
	and c.[Transaction Type] in ('Budget') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)
,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 ,isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Budget') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 ,isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--EBITDA % OF NET SALES BY SALE CHANNEL
--FORECAST - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'EBITDA' 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Sale Channel]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = ay.[Sale Channel]
	)

,aw as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	--,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(az.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 --,case --20 & 34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when az.[keyDimensionSetID] is null and az.[keyCountryCode] not in ('GB','GG','JE','IM') and (az.[Sale Channel] <> 'Intercompany' or az.[Sale Channel] is null) then 23 --34
		--else az.[keyDimensionSetID] --34
	 --end  --34
	 isnull(az.[keyDimensionSetID],20) --34
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		--,case --34 
			--when c.[keyCountryCode] not in ('GB','GG','JE','IM','ZZ') and (d.[Sale Channel] <> 'Intercompany' or d.[Sale Channel] is null) then 'International' --20 & 34
			--when (d.[Sale Channel] is null and c.[keyCountryCode] in ('GB','GG','JE','IM','ZZ'))  then 'Direct To Consumer' --34
		 --else d.[Sale Channel] --34
		 --end [Sale Channel] --34
		,isnull(nullif(d.[Sale Channel],'International'),'Direct to Consumer') [Sale Channel] --34
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(--19
			select 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Sale Channel]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	where 
		c.[Management Heading] = 'Net Sales' 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Sale Channel]
		,y.[Amount] 
	from 
		y 
	left join 
	(--19
		select 
			[Sale Channel] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Sale Channel] is not null 
		group by 
			[Sale Channel]
	) d 
	on 
		d.[Sale Channel] = y.[Sale Channel]
	)

,w as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end [keyDimensionSetID] --34
	,isnull(z.[keyDimensionSetID],20) [keyDimensionSetID] --34
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 --,case --20 & 34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] in ('GB','GG','JE','IM') then 20 --34
		--when z.[keyDimensionSetID] is null and z.[keyCountryCode] not in ('GB','GG','JE','IM') and (z.[Sale Channel] <> 'Intercompany' or z.[Sale Channel] is null) then 23 --34
		--else z.[keyDimensionSetID] --34
	 --end --34
	 isnull(z.[keyDimensionSetID],20)  --34
) 

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID]
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] --29
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) 
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	

--EBIDTA % BY JURISDICTION --37
--ACTUAL & FORECAST - Last Month This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'EBITDA'
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
--cross apply --45
join
	(select 
		 [period_date]
		,period_fom, period_eom
		,period_date_int 
	from 
		@table_ChartOfAccounts 
	where gl = 'MA10007'
	) t 
on
	(
		az.[keyTransactionDate] = t.period_date_int
	)
--where
--	az.[keyTransactionDate] = t.period_date_int
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
--cross apply --45
join
	(select 
		[period_date]
		, period_fom, period_eom
		, period_date_int 
	from 
		@table_ChartOfAccounts 
	where 
		gl = 'MA10007'
	) t 
on
	(
		 z.[keyTransactionDate] = t.period_date_int
	)
--where
--	 z.[keyTransactionDate] = t.period_date_int
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 ,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		

--EBIDTA % BY JURISDICTION --37
--ACTUAL & FORECAST - YTD This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'EBITDA'
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
/*
cross apply 
	(select 
		 [period_date]
		,period_fom, period_eom
		,period_date_int 
	from 
		@table_ChartOfAccounts 
	where gl = 'MA10007'
	) t 
where
	az.[keyTransactionDate] = t.period_date_int
*/
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
		and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 ,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 0 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--EBIDTA % BY JURISDICTION --37
--ACTUAL & FORECAST - Last Month Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'EBITDA'
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= dateadd(year,-1,dateadd(day,1,eomonth(convert(date,dateadd(month,-2,@getdate)))))
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[keyTransactionDate],w.[keyTransactionDate]) 
	,isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--EBIDTA % BY JURISDICTION --37
--ACTUAL & FORECAST - YTD Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'EBITDA'
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual','Forecast') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(year,-1,dateadd(month,-1,@getdate)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 1 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] 
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--EBIDTA % BY JURISDICTION --37
--ACTUAL - Full Year Last Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'EBITDA'
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in ('Actual') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate))-1,1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate))-1,12,31)
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 ,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 3 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]		


--EBIDTA % BY JURISDICTION --37
--BUDGET - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'EBITDA'
	and c.[Transaction Type] in ('Budget')  
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	 az.[keyTransactionDate]
	,az.[Transaction Type]
	,isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and c.[Transaction Type] in  ('Budget') 
	and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1)
	and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	 z.[keyTransactionDate]
	,z.[Transaction Type]
	 ,isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] --32
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	


--EBIDTA % BY JURISDICTION --37
--FORECAST - Full Year This Year
;with ay as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'EBITDA'
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 

,az as 
	(
	select 
		 ay.[keyTransactionDate]
		,ay.[Transaction Type]
		,ay.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,ay.[keyCountryCode]
		,d.[Jurisdiction]
		,ay.[Amount] 
	from 
		ay 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = ay.[Jurisdiction]
	)

,aw as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(az.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(az.[Amount]) [Amount]
from
	az
group by
	isnull(az.[keyDimensionSetID],30) 
) 

,y as 
	(
	select 
		 c.[keyTransactionDate]
		,c.[Transaction Type]
		,c.[keyGLAccountNo]
		,c.[keyDimensionSetID]
		,c.[keyCountryCode]
		,isnull(d.[Jurisdiction],fc.[Jurisdiction]) [Jurisdiction]
		,[Amount] 
	from 
		ext.ChartOfAccounts c 
	left join 
			(
			select 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			from 
				[finance].[MA_Dimensions] d 
			group by 
				 d.[Jurisdiction]
				,d.[keyDimensionSetID]
			) d 
			on 
				c.[keyDimensionSetID] = d.keyDimensionSetID
	join
		[finance].[Country] fc
	on
		c.[keyCountryCode] = fc.[keyCountryCode]
	where 
		c.[Management Heading] = 'Net Sales' 
	and 
		((c.[Transaction Type] in ('Actual') and convert(date,convert(nvarchar,c.keyTransactionDate)) >= datefromparts(year(dateadd(month,-1,@getdate)),1,1) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= eomonth(dateadd(month,-1,@getdate)))
	or
		(c.[Transaction Type] in ('Forecast') and convert(date,convert(nvarchar,c.keyTransactionDate)) > eomonth(dateadd(month,-1,@getdate)) and convert(date,convert(nvarchar,c.keyTransactionDate)) <= datefromparts(year(dateadd(month,-1,@getdate)),12,31)))
	) 

,z as 
	(
	select 
		 y.[keyTransactionDate]
		,y.[Transaction Type]
		,y.[keyGLAccountNo]
		,d.[keyDimensionSetID]
		,y.[keyCountryCode]
		,d.[Jurisdiction]
		,y.[Amount] 
	from 
		y 
	left join 
	(
		select 
			[Jurisdiction] 
			,min([keyDimensionSetID]) [keyDimensionSetID]	
		from 
			[finance].[MA_Dimensions]  
		where 
			[Jurisdiction] is not null 
		group by 
			[Jurisdiction]
	) d 
	on 
		d.[Jurisdiction] = y.[Jurisdiction]
	)

,w as
(
select
	 2 [keyTransactionDate]
	,'Forecast' [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(z.[keyDimensionSetID],30) [keyDimensionSetID] 
	,sum(z.[Amount]) [Amount]
from
	z
group by
	isnull(z.[keyDimensionSetID],30) 
)

insert into [ext].[ChartOfAccounts] ([keyTransactionDate],[Transaction Type],[keyGLAccountNo],[keyDimensionSetID],[keyCountryCode],[Management Heading],[Management Category],[Heading Sort],[Category Sort],[main],[invert],[ma],[Channel Category],[Channel Sort],[Amount],[_company]) --29
select
	 2 [keyTransactionDate]
	,isnull(aw.[Transaction Type],w.[Transaction Type]) [Transaction Type]
	,'MA10007' [keyGLAccountNo]
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID]) [keyDimensionSetID] 
	,'ZZ' [keyCountryCode]
	,ma.[Management Heading]
	,ma.[Management Category] [Management Category]
	,isnull(ma.[Heading Sort],0) [Heading Sort]
	,isnull(ma.[Category Sort],0) [Category Sort]
	,isnull(ma.[main],1) [main] 
	,isnull(ma.[invert],0)  [invert]
	,isnull(ma.[ma],0) [ma]
	,ma.[Channel Category] [Channel Category]
	,isnull(nullif(ma.[Channel Sort],''),0) [Channel Sort]
	,isnull(sum(aw.[Amount]),0)/nullif(isnull(sum(w.[Amount]),0),0) [Amount]
	,0 [_company] 
from 
	w
full join
	aw
on
	aw.[keyTransactionDate] = w.[keyTransactionDate]
and	aw.[Transaction Type] = w.[Transaction Type]
and aw.[keyDimensionSetID] = w.[keyDimensionSetID]
left join
	[ext].[ManagementAccounts] ma
on
	ma.[keyAccountCode] = isnull(aw.[keyGLAccountNo],w.[keyGLAccountNo])
group by
	 isnull(aw.[Transaction Type],w.[Transaction Type]) 
	,isnull(aw.[keyDimensionSetID],w.[keyDimensionSetID])
	,ma.[Management Heading]
    ,ma.[Management Category]
	,ma.[Heading Sort]
    ,ma.[Category Sort]
    ,ma.[main]
    ,ma.[invert]
    ,ma.[ma]
    ,ma.[Channel Category]
    ,ma.[Channel Sort]	
--19
update ext.[ChartOfAccounts] set [Channel Category] = '' where [keyGLAccountNo] = 'MA10003' and [keyDimensionSetID] in (1,2,3,4,5,6,7,8,9,10)
--19
update ext.[ChartOfAccounts] set [Management Heading] = '' where [keyGLAccountNo] = 'MA10003' and [keyDimensionSetID] in (20,21,22/*,23*/,24,25) --34

--19
delete from ext.[ChartOfAccounts] where [keyTransactionDate] < convert(int,format(dateadd(year,case when month(@getdate) = 1 then -2 else -1 end,datefromparts(year(@getdate),1,1)),'yyyyMMdd')) and [keyTransactionDate] not in (0,1,2,3)


--31
update [ext].[ChartOfAccounts] set [Amount] = 0 where [Amount] is NULL
GO