SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create or alter view  [finance].[MA_Dimensions]

--used in Management Accounts; includes dimension set ids and corresponding dimensions (department, legal entity, sale channel, reporting group and range code)
--also includes modification to dimension set ids for all companies but CompanyX; required for ChartOfAccounts structure
--01 removed [keyDimensionSetID] 23 for international as no longer needed for reporting
--02 added company name 
--03 added jurisdiction & HSNZ
--04 added dimensions for each jurisdiction
--05 added HSIE
--06 added new SALE.CHANNEL dimension Sports Trade (SPT)


as
--UK
with [ALL] as
	(
	select distinct
		[Dimension Set ID]
	from
		[dbo].[UK$Dimension Set Entry]
	)

, Department as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[UK$Dimension Set Entry] e
	join
		[dbo].[UK$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [Sale Channel] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[UK$Dimension Set Entry] e
	join
		[dbo].[UK$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)

, [Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[UK$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [Range Code] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[UK$Dimension Set Entry] e
	join
		[dbo].[UK$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[UK$Dimension Set Entry] e
	join
		[dbo].[UK$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

 , [Jurisdiction] as --03
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], v.[Name] [Description]
	from
		[dbo].[UK$Dimension Set Entry] e
	join
		[dbo].[UK$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)

, [Reporting Range] as
	(
	select
		r.keyReportingGroup, r.keyLegalEntity, r.[Reporting Range]
	from
		[ext].[MA_Reporting_Range] r
	)
--Group Eliminations
, [E_ALL] as
	(
	select distinct
		[Dimension Set ID]
	from
		[dbo].[CE$Dimension Set Entry]
	)

, [E_Department] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [E_Sale Channel] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALES.CHANNEL'
	)

, [E_Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[CE$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [E_Range Code] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [E_Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

  , [E_Jurisdiction] as --03
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], v.[Name] [Description]
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)

, [E_Reporting Range] as
	(
	select
		r.keyReportingGroup, r.keyLegalEntity, r.[Reporting Range]
	from
		[ext].[MA_Reporting_Range] r
	)
--CompanyX Europe
, [H_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[NL$Dimension Set Entry]
	)

, [H_Department] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[NL$Dimension Set Entry] e
	join
		[dbo].[NL$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [H_Sale Channel] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[NL$Dimension Set Entry] e
	join
		[dbo].[NL$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)

, [H_Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[NL$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [H_Range Code] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[NL$Dimension Set Entry] e
	join
		[dbo].[NL$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [H_Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[NL$Dimension Set Entry] e
	join
		[dbo].[NL$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

   , [H_Jurisdiction] as --03
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], v.[Name] [Description]
	from
		[dbo].[NL$Dimension Set Entry] e
	join
		[dbo].[NL$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)


, [H_Reporting Range] as
	(
	select
		r.keyReportingGroup, r.keyLegalEntity, r.[Reporting Range]
	from
		[ext].[MA_Reporting_Range] r
	)
--Quality Call Centre
, [Q_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[QC$Dimension Set Entry]
	)

, [Q_Department] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[QC$Dimension Set Entry] e
	join
		[dbo].[QC$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [Q_Sale Channel] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[QC$Dimension Set Entry] e
	join
		[dbo].[QC$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)

, [Q_Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[QC$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [Q_Range Code] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[QC$Dimension Set Entry] e
	join
		[dbo].[QC$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [Q_Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[QC$Dimension Set Entry] e
	join
		[dbo].[QC$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

, [Q_Jurisdiction] as --03
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], v.[Name] [Description]
	from
		[dbo].[QC$Dimension Set Entry] e
	join
		[dbo].[QC$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)

, [Q_Reporting Range] as
	(
	select
		r.keyReportingGroup, r.keyLegalEntity, r.[Reporting Range]
	from
		[ext].[MA_Reporting_Range] r
	)
--CompanyX New Zealand -03
, [NZ_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[NZ$Dimension Set Entry]
	)

, [NZ_Department] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [NZ_Sale Channel] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)

, [NZ_Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[NZ$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [NZ_Range Code] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [NZ_Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

   , [NZ_Jurisdiction] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], v.[Name] [Description]
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)


, [NZ_Reporting Range] as
	(
	select
		r.keyReportingGroup, r.keyLegalEntity, r.[Reporting Range]
	from
		[ext].[MA_Reporting_Range] r
	)


--CompanyX Ireland -05
, [IE_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[IE$Dimension Set Entry]
	)

, [IE_Department] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [IE_Sale Channel] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)

, [IE_Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[IE$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [IE_Range Code] as
	(
	select
		e.[Dimension Set ID], v.[Name] [Description]
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [IE_Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], e.[Dimension Value Code] + ' - ' + v.[Name] [Description]
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

   , [IE_Jurisdiction] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code], v.[Name] [Description]
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)


, [IE_Reporting Range] as
	(
	select
		r.keyReportingGroup, r.keyLegalEntity, r.[Reporting Range]
	from
		[ext].[MA_Reporting_Range] r
	)

	--UK
	select
	     1 [_company] --changed the company from 0 to 1
		,'UK' [Company] --02
		,a.[Dimension Set ID] [keyDimensionSetID]
		,d.[Description] Department
		,s.[Description] [Sale Channel]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Description] [Range Code]
		,g.[Description] [Reporting Group]
		,j.[Description] [Jurisdiction]
		,rr.[Reporting Range]
	from
		[ALL] a
	left join
		Department d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]
	left join
		[Reporting Range] rr
	on
		coalesce(nullif(g.[Dimension Value Code],''),'000') = rr.keyReportingGroup
	and e.[Dimension Value Code] = rr.keyLegalEntity
	

	union all

	--Group Eliminations
	select
	     2 [_company] --changed the company from 1 to 2
		,'CE' [Company] --02
		,20000 + a.[Dimension Set ID] [keyDimensionSetID] --changed from 10000 to 20000
		,d.[Description] Department
		,s.[Description] [Sale Channel]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Description] [Range Code]
		,g.[Description] [Reporting Group]
		,j.[Description] [Jurisdiction]
		,rr.[Reporting Range]
	from
		[E_ALL] a
	left join
		[E_Department] d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[E_Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[E_Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[E_Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[E_Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[E_Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]
	left join
		[E_Reporting Range] rr
	on
		coalesce(nullif(g.[Dimension Value Code],''),'000') = rr.keyReportingGroup
	and e.[Dimension Value Code] = rr.keyLegalEntity


	union all

	--CompanyX Europe
	select
	     4 [_company] --changed the company from 2 to 4
		,'CompanyX Europe' [Company] --02
		,40000 + a.[Dimension Set ID] [keyDimensionSetID] --changed from 20000 to 40000
		,d.[Description] Department
		,s.[Description] [Sale Channel]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Description] [Range Code]
		,g.[Description] [Reporting Group]
		,j.[Description] [Jurisdiction]
		,rr.[Reporting Range]
	from
		[H_ALL] a
	left join
		[H_Department] d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[H_Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[H_Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[H_Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[H_Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[H_Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]
	left join
		[H_Reporting Range] rr
	on
		coalesce(nullif(g.[Dimension Value Code],''),'000') = rr.keyReportingGroup
	and e.[Dimension Value Code] = rr.keyLegalEntity

	union all

	--Quality Call Centre
	select
	     3 [_company] 
		,'Quality Call Centre' [Company] --02
		,30000 + a.[Dimension Set ID] [keyDimensionSetID]
		,d.[Description] Department
		,s.[Description] [Sale Channel]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Description] [Range Code]
		,g.[Description] [Reporting Group]
		,j.[Description] [Jurisdiction]
		,rr.[Reporting Range]
	from
		[Q_ALL] a
	left join
		[Q_Department] d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[Q_Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[Q_Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[Q_Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[Q_Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[Q_Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]
	left join
		[Q_Reporting Range] rr
	on
		coalesce(nullif(g.[Dimension Value Code],''),'000') = rr.keyReportingGroup
	and e.[Dimension Value Code] = rr.keyLegalEntity

union all

	--CompanyX New Zealand --03
	select
	     5 [_company] 
		,'CompanyX New Zealand' [Company]
		,50000 + a.[Dimension Set ID] [keyDimensionSetID] 
		,d.[Description] Department
		,s.[Description] [Sale Channel]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Description] [Range Code]
		,g.[Description] [Reporting Group]
		,j.[Description] [Jurisdiction]
		,rr.[Reporting Range]
	from
		[NZ_ALL] a
	left join
		[NZ_Department] d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[NZ_Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[NZ_Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[NZ_Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[NZ_Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[NZ_Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]
	left join
		[NZ_Reporting Range] rr
	on
		coalesce(nullif(g.[Dimension Value Code],''),'000') = rr.keyReportingGroup
	and e.[Dimension Value Code] = rr.keyLegalEntity


union all

	--CompanyX Ireland --05
	select
	     6 [_company] 
		,'CompanyX Ireland' [Company]
		,60000 + a.[Dimension Set ID] [keyDimensionSetID] 
		,d.[Description] Department
		,s.[Description] [Sale Channel]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Description] [Range Code]
		,g.[Description] [Reporting Group]
		,j.[Description] [Jurisdiction]
		,rr.[Reporting Range]
	from
		[IE_ALL] a
	left join
		[IE_Department] d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[IE_Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[IE_Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[IE_Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[IE_Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[IE_Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]
	left join
		[IE_Reporting Range] rr
	on
		coalesce(nullif(g.[Dimension Value Code],''),'000') = rr.keyReportingGroup
	and e.[Dimension Value Code] = rr.keyLegalEntity

--reporting range
union all
select 0, 'Group Consolidation', 1, NULL, NULL, NULL, NULL, NULL, NULL, 'Group Consolidation' --02
union all
select 1, 'UK', 2, NULL, NULL, NULL, NULL, NULL, NULL, 'CompanyX Ltd' --Changed _company from 0 to 1 --02
union all
select 1, 'UK', 3, NULL, NULL, NULL, NULL, NULL, NULL, 'CompanyX UK' --Changed _company from 0 to 1
union all
select 0, 'Group Consolidation', 4, NULL, NULL, NULL, NULL, NULL, NULL, 'Nurture' --Changed _company from 0 to 1 --changed to 0 as now Nurture, Petcare, Elite and VMS include transactions from 1,3,4,5 companies --02
union all
select 0, 'Group Consolidation', 5, NULL, NULL, NULL, NULL, NULL, NULL, 'Petcare' --Changed _company from 0 to 1 --changed to 0 as now Nurture, Petcare, Elite and VMS include transactions from 1,3,4,5 companies --02
union all
select 0, 'Group Consolidation', 6, NULL, NULL, NULL, NULL, NULL, NULL, 'VMS'  --Changed _company from 0 to 1 --changed to 0 as now Nurture, Petcare, Elite and VMS include transactions from 1,3,4,5 companies --02
union all
select 0, 'Group Consolidation', 7, NULL, NULL, NULL, NULL, NULL, NULL, 'Elite' --Changed _company from 0 to 1 --changed to 0 as now Nurture, Petcare, Elite and VMS include transactions from 1,3,4,5 companies --02
union all
select 4, 'CompanyX Europe', 8, NULL, NULL, NULL, NULL, NULL, NULL, 'CompanyX Europe' --Changed _company from 0 to 4 --02
union all
select 3, 'Quality Call Centre', 9, NULL, NULL, NULL, NULL, NULL, NULL, 'Quality Call Centre' --Changed _company from 0 to 3 --02
union all
select 5, 'CompanyX New Zealand', 10, NULL, NULL, NULL, NULL, NULL, NULL, 'CompanyX New Zealand' --03
union all --05
select 6, 'CompanyX Ireland', 11, NULL, NULL, NULL, NULL, NULL, NULL, 'CompanyX Ireland' --05

--sales channel
union all
select 0, 'Group Consolidation', 20, NULL, 'Direct to Consumer', NULL, NULL, NULL, NULL, NULL --02
union all
select 0, 'Group Consolidation', 21, NULL, '3rd Party Online', NULL, NULL, NULL, NULL, NULL --02
union all
select 0, 'Group Consolidation', 22, NULL, 'Bricks and Mortar', NULL, NULL, NULL, NULL, NULL --02
--union all --01
--select 0, 23, NULL, 'International', NULL, NULL, NULL, NULL, NULL 
union all
select 0, 'Group Consolidation', 24, NULL, 'Market Place Platforms', NULL, NULL, NULL, NULL, NULL --02
union all
select 0, 'Group Consolidation', 25, NULL, 'Intercompany', NULL, NULL, NULL, NULL, NULL --02
union all
select 0, 'Group Consolidation', 26, NULL, 'Sports Trade', NULL, NULL, NULL, NULL, NULL --06

--jurisdiction --04
union all
select 0, 'Group Consolidation', 30, NULL, NULL, NULL, NULL, NULL, 'United Kingdom', NULL
union all
select 0, 'Group Consolidation', 31, NULL, NULL, NULL, NULL, NULL, 'Australia', NULL
union all
select 0, 'Group Consolidation', 32, NULL, NULL, NULL, NULL, NULL, 'Ireland', NULL
union all
select 0, 'Group Consolidation', 33, NULL, NULL, NULL, NULL, NULL, 'New Zealand', NULL
union all
select 0, 'Group Consolidation', 34, NULL, NULL, NULL, NULL, NULL, 'Europe', NULL
union all
select 0, 'Group Consolidation', 35, NULL, NULL, NULL, NULL, NULL, 'Rest of World', NULL
GO
