SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE or ALTER view [ext].[AutoNAV_Shipping_Invoicing_Jobs]

as

with x
as
(
select
     [AutoNAV Task ID] 
    ,max([Entry No_]) lastEntry
from
    [dbo].[UK$AutoNAV Task Log Entry] x
where
    [AutoNAV Task ID] in ('b63a94ae-5f15-46eb-b299-9d61e7e31bc0','90fe46af-ab16-4c0e-9daf-3f1194a0f9a5')
group by
      [AutoNAV Task ID] 
)


select  
     y.[Description] [AutoNAV Task]
    ,db_sys.fn_Lookup('AutoNAV Task','Status',y.[Status]) [Status]
    ,db_sys.fn_datediff_string([Start Date_Time],isnull(nullif([End Date_Time],'17530101'),getutcdate()),2) [Duration]
from
    [dbo].[UK$AutoNAV Task Log Entry] y
join
    x
on
    (
        x.lastEntry = y.[Entry No_]
    )
where
    y.[Status] in (1,2)
GO