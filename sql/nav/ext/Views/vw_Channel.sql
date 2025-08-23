CREATE view [ext].[vw_Channel]

as

select 
     d.Code Channel_Code
    ,d.[Description] Channel_Description
    ,g.[Description] Group_Description 
from 
    [UK$Channel] d 
join 
    ext.Channel e 
on 
    d.Code = e.Channel_Code 
join 
    ext.Channel_Grouping g 
on 
    e.Group_Code = g.Code


union all

select
     d.Code
    ,d.[Description]
    ,g.[Description]
from
    [UK$Channel] d,ext.Channel_Grouping g
where
    d.Code not in (select Channel_Code from ext.Channel)
and g.Code = 7
GO
