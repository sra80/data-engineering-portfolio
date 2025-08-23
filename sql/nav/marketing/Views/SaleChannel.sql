






CREATE  view [marketing].[SaleChannel]

as	
	

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
		e.[Dimension Set ID], v.[Name] [Description], v.[Code]
	from
		[dbo].[UK$Dimension Set Entry] e
	join
		[dbo].[UK$Dimension Value] v
	on
		e.[Dimension Value Code] = v.Code and e.[Dimension Code] = v.[Dimension Code]
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)


select
	 a.[Dimension Set ID] [keyDimensionSetID]
	,s.[Description] [Recorded Sale Channel]
	,s.[Code]
from
	[ALL] a
left join
	[Sale Channel] s
on
	a.[Dimension Set ID] = s.[Dimension Set ID]
GO
