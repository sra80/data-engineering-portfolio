





CREATE view [ext].[G_L_Budget_Entry]

as

select
	 b.[Budget Name]
	,b.[Year]
	,1 [_company] --221124 changed company from 0 to 1
	,case when [min Entry No_] = min([min Entry No_]) over (partition by [Year]) then 1 else 0 end is_base
	,case when [max Entry No_] = max([max Entry No_]) over (partition by [Year]) then 1 else 0 end is_comparative
from
	(
		select 
			 [Budget Name]
			,year([Date]) [Year]
			,min([Entry No_]) [min Entry No_]
			,max([Entry No_]) [max Entry No_]
			,min([Date]) [min Date]
		from
			[dbo].[UK$G_L Budget Entry]
		group by
			 [Budget Name]
			,year([Date])
	) b

union all

select
	 b.[Budget Name]
	,b.[Year]
	,2 [_company] --221124 changed company from 1 to 2
	,case when [min Entry No_] = min([min Entry No_]) over (partition by [Year]) then 1 else 0 end is_base
	,case when [max Entry No_] = max([max Entry No_]) over (partition by [Year]) then 1 else 0 end is_comparative
from
	(
		select 
			 [Budget Name]
			,year([Date]) [Year]
			,min([Entry No_]) [min Entry No_]
			,max([Entry No_]) [max Entry No_]
			,min([Date]) [min Date]
		from
			[dbo].[CE$G_L Budget Entry]
		group by
				[Budget Name]
			,year([Date])
	) b

union all

select
	 b.[Budget Name]
	,b.[Year]
	,3 [_company]
	,case when [min Entry No_] = min([min Entry No_]) over (partition by [Year]) then 1 else 0 end is_base
	,case when [max Entry No_] = max([max Entry No_]) over (partition by [Year]) then 1 else 0 end is_comparative
from
	(
		select 
			 [Budget Name]
			,year([Date]) [Year]
			,min([Entry No_]) [min Entry No_]
			,max([Entry No_]) [max Entry No_]
			,min([Date]) [min Date]
		from
			[dbo].[QC$G_L Budget Entry]
		group by
				[Budget Name]
			,year([Date])
	) b

union all

select
	 b.[Budget Name]
	,b.[Year]
	,4 [_company]
	,case when [min Entry No_] = min([min Entry No_]) over (partition by [Year]) then 1 else 0 end is_base
	,case when [max Entry No_] = max([max Entry No_]) over (partition by [Year]) then 1 else 0 end is_comparative
from
	(
		select 
			 [Budget Name]
			,year([Date]) [Year]
			,min([Entry No_]) [min Entry No_]
			,max([Entry No_]) [max Entry No_]
			,min([Date]) [min Date]
		from
			[dbo].[NL$G_L Budget Entry]
		group by
			 [Budget Name]
			,year([Date])
	) b

union all

select
	 b.[Budget Name]
	,b.[Year]
	,5 [_company]
	,case when [min Entry No_] = min([min Entry No_]) over (partition by [Year]) then 1 else 0 end is_base
	,case when [max Entry No_] = max([max Entry No_]) over (partition by [Year]) then 1 else 0 end is_comparative
from
	(
		select 
			 [Budget Name]
			,year([Date]) [Year]
			,min([Entry No_]) [min Entry No_]
			,max([Entry No_]) [max Entry No_]
			,min([Date]) [min Date]
		from
			[dbo].[NZ$G_L Budget Entry]
		group by
			 [Budget Name]
			,year([Date])
	) b


union all

select
	 b.[Budget Name]
	,b.[Year]
	,6 [_company]
	,case when [min Entry No_] = min([min Entry No_]) over (partition by [Year]) then 1 else 0 end is_base
	,case when [max Entry No_] = max([max Entry No_]) over (partition by [Year]) then 1 else 0 end is_comparative
from
	(
		select 
			 [Budget Name]
			,year([Date]) [Year]
			,min([Entry No_]) [min Entry No_]
			,max([Entry No_]) [max Entry No_]
			,min([Date]) [min Date]
		from
			[dbo].[IE$G_L Budget Entry]
		group by
			 [Budget Name]
			,year([Date])
	) b
GO
