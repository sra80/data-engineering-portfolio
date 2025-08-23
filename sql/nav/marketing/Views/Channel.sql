
create   view [marketing].[Channel]

as

select 
     e.ID key_channel
    ,concat(case when d.company_id = 1 then null else d.company_id end,d.code) [ord_chann_code]
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
