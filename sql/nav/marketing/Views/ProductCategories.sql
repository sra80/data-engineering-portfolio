
create   view [marketing].[ProductCategories]

as

select Item.ID sku, category from ext.Item_Category join ext.Item on Item_Category.sku = Item.No_

union all

select ID, 'not set' from ext.Item where No_ not in (select sku from ext.Item_Category)
GO
