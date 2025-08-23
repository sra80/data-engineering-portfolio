create   view [marketing].[ProductInsight] 

as 

select 
    parent.ID parent,
    child.ID child, 
    scale 
from 
    ext.Item_Insight ii 
join 
    ext.Item child 
on 
    (
        ii.child = child.No_
    )
join 
    ext.Item parent 
on 
    (
        child.company_id = parent.company_id
    and ii.parent = parent.No_
    )

union all

select 
    ID,
    ID, 
    1 
from 
    ext.Item 
where 
    (
        No_ not in (select child from ext.Item_Insight) 
    and exists (select 1 from hs_consolidated.Item hci where Item.company_id = hci.company_id and Item.No_ = hci.No_)
    )
GO
