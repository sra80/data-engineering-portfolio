CREATE view [ext].[AutoNAV_Tasks]

as


select --[Status], --0 'Ready'; 1 'In Process'; 3 'On Hold'; 4 - Finished 
	c.[Company]
   ,ant.[AutoNAV Task Queue Code] [AutoNAV Queue]
   ,ant.[Description] [AutoNAV Task]
   --,ant.[Last Ready State]
from
	[hs_consolidated].[AutoNAV Task] ant
join
	db_sys.[Company] c
on
	(
		c.ID = ant.[company_id]
	)
where
	ant.[Status] = 4
and ant.[Earliest Start Date_Time] < dateadd(minute, - 15, getutcdate())
GO
