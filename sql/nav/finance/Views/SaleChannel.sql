SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create or alter view [finance].[SaleChannel]


as	

--used in ChartOfAccounts model

--modified by AJ 20230103 09:58 - change required due to NZ company implemenation - error "Column 'keyDimensionSetID' in Table 'SaleChannel' contains a duplicate value '21' and this is not allowed for columns on the one side of a many-to-one relationship or for columns that are used as the primary key of a table."
--modifications needed to dimension set ids for all companies, but UK; required for ChartOfAccounts structure, otherwise overlap with dimesnsion set Ids 20,21,22,23,24,25 which are only used with comapny 0 for SaleChannel breakdown 
--01 removed [keyDimensionSetID] 23 for international as no longer needed for reporting
--02 added HSNZ
--03 added HSIE
--04 added new SALE.CHANNEL dimension Sports Trade (SPT)

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
		e.[Dimension Code] = 'SALE.CHANNEL'
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
		e.[Dimension Code] = 'SALES.CHANNEL'
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
		e.[Dimension Code] = 'SALE.CHANNEL'
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
		e.[Dimension Code] = 'SALE.CHANNEL'
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
		e.[Dimension Code] = 'SALE.CHANNEL'
	)
--CompanyX Ireland --03
, [IE_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[IE$Dimension Set Entry]
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

--UK
select
	 1 [_company]
	,a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Sale Channel]
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
	,s.[Description] [Recorded Sale Channel]
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
	,s.[Description] [Recorded Sale Channel]
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
	,s.[Description] [Recorded Sale Channel]
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
	,s.[Description] [Recorded Sale Channel]
from
	[NZ_ALL] a
left join
	[NZ_Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]

union all

--CompanyX Ireland --03
select
	 6 [_company]
	,60000 + a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Sale Channel]
from
	[IE_ALL] a
left join
	[IE_Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]


union all
select 0, 20, 'Direct to Consumer'
union all
select 0, 21, '3rd Party Online'
union all
select 0, 22, 'Bricks and Mortar'
--01
--union all
--select 0, 23, 'International'
union all
select 0, 24, 'Market Place Platforms'
union all
select 0, 25, 'Intercompany'
union all
select 0, 26, 'Sports Trade' --04
GO
