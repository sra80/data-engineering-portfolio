
create   view finance.Channel

as

select 
     e.ID [keyChannelCode]
    ,d.[Description] [Channel]
    ,g.[Description] [Group Channel]
from 
    hs_consolidated.Channel d 
join 
    ext.Channel e 
on 
    (
        d.company_id = e.company_id
    and d.Code = e.Channel_Code
    )
join 
    ext.Channel_Grouping g 
on 
    e.Group_Code = g.Code
GO
