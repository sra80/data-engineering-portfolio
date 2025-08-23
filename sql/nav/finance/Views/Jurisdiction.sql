
CREATE view [finance].[Jurisdiction]


as	

--used in ChartOfAccounts model


--UK
with [ALL] as
	(
	select distinct
		[Dimension Set ID]
	from
		[dbo].[UK$Dimension Set Entry]
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
		e.[Dimension Code] = 'JURISDICTION'
	)
--Group Eliminations
, [E_ALL] as
	(
	select distinct
		[Dimension Set ID]
	from
		[dbo].[CE$Dimension Set Entry]
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
		e.[Dimension Code] = 'JURISDICTION'
	)
--CompanyX Europe
, [H_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[NL$Dimension Set Entry]
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
		e.[Dimension Code] = 'JURISDICTION'
	)

--Quality Call Centre
, [Q_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[QC$Dimension Set Entry]
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
		e.[Dimension Code] = 'JURISDICTION'
	)

--CompanyX New Zealand --02
, [NZ_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[NZ$Dimension Set Entry]
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
		e.[Dimension Code] = 'JURISDICTION'
	)

--CompanyX Ireland --03
, [IE_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[NZ$Dimension Set Entry]
	)

, [IE_Sale Channel] as
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
		e.[Dimension Code] = 'JURISDICTION'
	)

--UK
select
	 1 [_company]
	,a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Jurisdiction]
from
	[ALL] a
left join
	[Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]

union all

--Group Eliminations
select
	 2 [_company]
	,20000 + a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Jurisdiction]
from
	[E_ALL] a
left join
	[E_Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]

union all

--CompanyX Europe
select
	 4 [_company]
	,40000 + a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Jurisdiction]
from
	[H_ALL] a
left join
	[H_Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]

union all

--Quality Call Centre
select
	 3 [_company]
	,30000 + a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Jurisdiction]
from
	[H_ALL] a
left join
	[Q_Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]

union all

--CompanyX New Zealand
select
	 5 [_company]
	,50000 + a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Jurisdiction]
from
	[NZ_ALL] a
left join
	[NZ_Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]

union all

--CompanyX Ireland
select
	 6 [_company]
	,60000 + a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Jurisdiction]
from
	[IE_ALL] a
left join
	[IE_Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]

union all
select 0, 30, 'United Kingdom'
union all
select 0, 31, 'Australia'
union all
select 0, 32, 'Ireland'
union all
select 0, 33, 'New Zealand'
union all
select 0, 34, 'Europe'
union all
select 0, 35, 'Rest of World'
GO
