
create   view [finance].[Dimensions]

as

with [ALL] as
	(
	select distinct
		(dse.company_id*10000)+dse.[Dimension Set ID] keyDimensionSetID,
		default_sale_channel.[Sale Channel Code],
		default_sale_channel.[Sale Channel]
	from
		[hs_consolidated].[Dimension Set Entry] dse
	-- join
	-- 	(
	-- 		select 
	-- 			(1*10000)+ve.[Dimension Set ID] [keyDimensionSetID] 
	-- 		from
	-- 			[dbo].[UK$Value Entry] ve
	-- 		where
	-- 			(
	-- 				[Item Ledger Entry Type] = 1 
	-- 			and [Document Type] in (0,2,4)
	-- 			and ve.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
	-- 			)

	-- 		union

	-- 		select 
	-- 			(4*10000)+ve.[Dimension Set ID] [keyDimensionSetID] 
	-- 		from
	-- 			[dbo].[NL$Value Entry] ve
	-- 		where
	-- 			(
	-- 				[Item Ledger Entry Type] = 1 
	-- 			and [Document Type] in (2,4)
	-- 			and ve.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
	-- 			)

	-- 		union

	-- 		select 
	-- 			(6*10000)+ve.[Dimension Set ID] [keyDimensionSetID] 
	-- 		from
	-- 			[dbo].[IE$Value Entry] ve
	-- 		where
	-- 			(
	-- 				[Item Ledger Entry Type] = 1 
	-- 			and [Document Type] in (2,4)
	-- 			and ve.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
	-- 			)

	-- 		union

	-- 		select 
	-- 			(5*10000)+ve.[Dimension Set ID] [keyDimensionSetID] 
	-- 		from
	-- 			[dbo].[NZ$Value Entry] ve
	-- 		where
	-- 			(
	-- 				[Item Ledger Entry Type] = 1 
	-- 			and [Document Type] in (2,4)
	-- 			and ve.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
	-- 			)
	-- 	) ve
	-- on
	-- 	(
	-- 		(dse.company_id*10000)+dse.[Dimension Set ID] = ve.keyDimensionSetID
	-- 	)
	left join
		(
			select 
				company_id,
				[Code] [Sale Channel Code],
				[Name] [Sale Channel]
			from 
				[hs_consolidated].[Dimension Value] 
			where 
				(
					[Dimension Code] = 'SALE.CHANNEL' 
				and [Code] = 'D2C'
				)
		) default_sale_channel
	on
		(
			dse.company_id = default_sale_channel.company_id
		)
	)

, Department as
	(
	select
		(e.company_id*10000)+e.[Dimension Set ID] keyDimensionSetID,
        e.[Dimension Value Code] + ' - ' + v.[Name] [Department]
	from
		[hs_consolidated].[Dimension Set Entry] e
	join
		[hs_consolidated].[Dimension Value] v
	on
		(
            e.company_id = v.company_id 
        and e.[Dimension Value Code] = v.Code 
        and e.[Dimension Code] = v.[Dimension Code]
        )
	where
		e.[Dimension Code] = 'DEPARTMENT'
	)

, [Sale Channel] as
	(
	select
		(e.company_id*10000)+e.[Dimension Set ID] keyDimensionSetID,
        [Dimension Value Code] [Sale Channel Code],
        v.[Name] [Sale Channel]
	from
		[hs_consolidated].[Dimension Set Entry] e
	join
		[hs_consolidated].[Dimension Value] v
	on
		(
            e.company_id = v.company_id 
        and e.[Dimension Value Code] = v.Code 
        and e.[Dimension Code] = v.[Dimension Code]
        )
	where
		e.[Dimension Code] = 'SALE.CHANNEL'
	)

, [Legal Entity] as
	(
	select
		(e.company_id*10000)+e.[Dimension Set ID] keyDimensionSetID,
        e.[Dimension Value Code] [Legal Entity]
	from
		[hs_consolidated].[Dimension Set Entry] e
	where
		[Dimension Code] = 'ENTITY'
	)

, [Range Code] as
	(
	select
		(e.company_id*10000)+e.[Dimension Set ID] keyDimensionSetID,
        v.[Name] [Range Code]
	from
		[hs_consolidated].[Dimension Set Entry] e
	join
		[hs_consolidated].[Dimension Value] v
	on
		(
            e.company_id = v.company_id 
        and e.[Dimension Value Code] = v.Code 
        and e.[Dimension Code] = v.[Dimension Code]
        )
	where
		e.[Dimension Code] = 'RANGE'
	)

, [Reporting Group] as
	(
	select
		(e.company_id*10000)+e.[Dimension Set ID] keyDimensionSetID,
        e.[Dimension Value Code] + ' - ' + v.[Name] [Reporting Group]
	from
		[hs_consolidated].[Dimension Set Entry] e
	join
		[hs_consolidated].[Dimension Value] v
	on
		(
            e.company_id = v.company_id 
        and e.[Dimension Value Code] = v.Code 
        and e.[Dimension Code] = v.[Dimension Code]
        )
	where
		e.[Dimension Code] = 'REP.GRP'
	)

	select
	     a.[keyDimensionSetID]
		,d.[Department]
		,isnull(s.[Sale Channel Code],a.[Sale Channel Code]) [Sale Channel Code]
		,isnull(s.[Sale Channel],a.[Sale Channel]) [Sale Channel]
		,e.[Legal Entity] [Legal Entity]
		,r.[Range Code]
		,g.[Reporting Group]
	from
		[ALL] a
	left join
		Department d
	on
		a.[keyDimensionSetID] = d.[keyDimensionSetID]
	left join
		[Sale Channel] s
	on
		a.[keyDimensionSetID] = s.[keyDimensionSetID]
	left join
		[Legal Entity] e
	on
		a.[keyDimensionSetID] = e.[keyDimensionSetID]
	left join
		[Range Code] r
	on
		a.[keyDimensionSetID] = r.[keyDimensionSetID]
	left join
		[Reporting Group] g
	on
		a.[keyDimensionSetID] = g.[keyDimensionSetID]
GO
