create view price_tool_feed.article_classes

as

select
    a.article_id,
    isnull(d.decile,10) class_id,
    concat(isnull(d.decile,10),case d.decile when 1 then 'st' when 2 then 'nd' when 3 then 'rd' else 'th' end,' Decile') class_name
from
  price_tool_feed.articles a
outer apply 
    ext.fn_Item_Decile(a.article_id,default,default) d
GO
