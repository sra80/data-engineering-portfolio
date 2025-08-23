







CREATE view [ext].[Dimensions]

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
		e.[Dimension Set ID], e.[Dimension Value Code]  
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
		e.[Dimension Set ID], [Dimension Value Code]  
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
		e.[Dimension Set ID], [Dimension Value Code]
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
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[UK$Dimension Set Entry] e
	join
		[dbo].[UK$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

  , [Jurisdiction] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[UK$Dimension Set Entry] e
	join
		[dbo].[UK$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)


--NL
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
		e.[Dimension Set ID], e.[Dimension Value Code] 
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
		e.[Dimension Set ID], [Dimension Value Code] 
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
		e.[Dimension Set ID], [Dimension Value Code]
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
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[NL$Dimension Set Entry] e
	join
		[dbo].[NL$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

 , [H_Jurisdiction] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[NL$Dimension Set Entry] e
	join
		[dbo].[NL$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)

--CE
,  [CE_ALL] as
	(
	select distinct
		 [Dimension Set ID]
	from
		[dbo].[CE$Dimension Set Entry]
	)

, [CE_Department] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code] 
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [CE_Sale Channel] as
	(
	select
		e.[Dimension Set ID], [Dimension Value Code] 
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALES.CHANNEL'
	)

, [CE_Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[CE$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [CE_Range Code] as
	(
	select
		e.[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [CE_Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

 , [CE_Jurisdiction] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[CE$Dimension Set Entry] e
	join
		[dbo].[CE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)

--QCAL
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
		e.[Dimension Set ID], e.[Dimension Value Code] 
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
		e.[Dimension Set ID], [Dimension Value Code] 
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
		e.[Dimension Set ID], [Dimension Value Code]
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
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[QC$Dimension Set Entry] e
	join
		[dbo].[QC$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

 , [Q_Jurisdiction] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[QC$Dimension Set Entry] e
	join
		[dbo].[QC$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)

--New Zealand
 , [HSNZ_ALL] as
	(
	select distinct
		[Dimension Set ID]
	from
		[dbo].[NZ$Dimension Set Entry]
	)

, [HSNZ_Department] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]  
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [HSNZ_Sale Channel] as
	(
	select
		e.[Dimension Set ID], [Dimension Value Code]  
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)

, [HSNZ_Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[NZ$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [HSNZ_Range Code] as
	(
	select
		e.[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [HSNZ_Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

 , [HSNZ_Jurisdiction] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[NZ$Dimension Set Entry] e
	join
		[dbo].[NZ$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)

--Ireland
 , [HSIE_ALL] as
	(
	select distinct
		[Dimension Set ID]
	from
		[dbo].[IE$Dimension Set Entry]
	)

, [HSIE_Department] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]  
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [HSIE_Sale Channel] as
	(
	select
		e.[Dimension Set ID], [Dimension Value Code]  
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)

, [HSIE_Legal Entity] as
	(
	select
		[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[IE$Dimension Set Entry]
	where
		[Dimension Code] = 'ENTITY'
	)

, [HSIE_Range Code] as
	(
	select
		e.[Dimension Set ID], [Dimension Value Code]
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'RANGE'
	)

, [HSIE_Reporting Group] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'REP.GRP'
	)

 , [HSIE_Jurisdiction] as
	(
	select
		e.[Dimension Set ID], e.[Dimension Value Code]
	from
		[dbo].[IE$Dimension Set Entry] e
	join
		[dbo].[IE$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'JURISDICTION'
	)
	select
	     1 [_company]
		,a.[Dimension Set ID] [keyDimensionSetID]
		,d.[Dimension Value Code] Department
		,s.[Dimension Value Code] [Sales Channel]
		,j.[Dimension Value Code] [Jurisdiction]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Dimension Value Code] [Range Code]
		,g.[Dimension Value Code] [Reporting Group]
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

	union all

	select
	     2 [_company]
		,20000 + a.[Dimension Set ID] [keyDimensionSetID]
		,d.[Dimension Value Code] Department
		,s.[Dimension Value Code] [Sales Channel]
		,j.[Dimension Value Code] [Jurisdiction]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Dimension Value Code] [Range Code]
		,g.[Dimension Value Code] [Reporting Group]
	from
		[CE_ALL] a
	left join
		[CE_Department] d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[CE_Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[CE_Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[CE_Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[CE_Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[CE_Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]

	union all

	select
	     3 [_company]
		,30000 + a.[Dimension Set ID] [keyDimensionSetID]
		,d.[Dimension Value Code] Department
		,s.[Dimension Value Code] [Sales Channel]
		,j.[Dimension Value Code] [Jurisdiction]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Dimension Value Code] [Range Code]
		,g.[Dimension Value Code] [Reporting Group]
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

	union all

	select
	     4 [_company]
		,40000 + a.[Dimension Set ID] [keyDimensionSetID]
		,d.[Dimension Value Code] Department
		,s.[Dimension Value Code] [Sales Channel]
		,j.[Dimension Value Code] [Jurisdiction]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Dimension Value Code] [Range Code]
		,g.[Dimension Value Code] [Reporting Group]
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

    union all

	select
	     5 [_company]
		,50000 + a.[Dimension Set ID] [keyDimensionSetID]
		,d.[Dimension Value Code] Department
		,s.[Dimension Value Code] [Sales Channel]
		,j.[Dimension Value Code] [Jurisdiction]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Dimension Value Code] [Range Code]
		,g.[Dimension Value Code] [Reporting Group]
	from
		[HSNZ_ALL] a
	left join
		[HSNZ_Department] d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[HSNZ_Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[HSNZ_Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[HSNZ_Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[HSNZ_Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[HSNZ_Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]
	
	union all

	select
	     6 [_company]
		,60000 + a.[Dimension Set ID] [keyDimensionSetID]
		,d.[Dimension Value Code] Department
		,s.[Dimension Value Code] [Sales Channel]
		,j.[Dimension Value Code] [Jurisdiction]
		,e.[Dimension Value Code] [Legal Entity]
		,r.[Dimension Value Code] [Range Code]
		,g.[Dimension Value Code] [Reporting Group]
	from
		[HSIE_ALL] a
	left join
		[HSIE_Department] d
	on
		a.[Dimension Set ID] = d.[Dimension Set ID]
	left join
		[HSIE_Sale Channel] s
	on
		a.[Dimension Set ID] = s.[Dimension Set ID]
	left join
		[HSIE_Legal Entity] e
	on
		a.[Dimension Set ID] = e.[Dimension Set ID]
	left join
		[HSIE_Range Code] r
	on
		a.[Dimension Set ID] = r.[Dimension Set ID]
	left join
		[HSIE_Reporting Group] g
	on
		a.[Dimension Set ID] = g.[Dimension Set ID]
	left join
		[HSIE_Jurisdiction] j
	on
		a.[Dimension Set ID] = j.[Dimension Set ID]
GO
