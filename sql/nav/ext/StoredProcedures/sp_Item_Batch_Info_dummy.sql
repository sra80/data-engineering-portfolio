--ext.sp_Item_Batch_Info_dummy

create   procedure ext.sp_Item_Batch_Info_dummy

as

set nocount on

insert into ext.Item_Batch_Info (company_id, sku, variant_code, batch_no)
select 
    company_id,
    No_,
    'dummy',
    'Not Provided'
from
    ext.Item
where
    (
        not exists (select 1 from ext.Item_Batch_Info where Item.company_id = Item_Batch_Info.company_id and Item.No_ = Item_Batch_Info.sku and variant_code = 'dummy' and batch_no = 'Not Provided')
    )

insert into ext.Item_Batch_Info (company_id, sku, variant_code, batch_no)
select 
    company_id,
    No_,
    'dummy',
    'On Order'
from
    ext.Item
where
    (
        not exists (select 1 from ext.Item_Batch_Info where Item.company_id = Item_Batch_Info.company_id and Item.No_ = Item_Batch_Info.sku and variant_code = 'dummy' and batch_no = 'On Order')
    )

insert into ext.Item_Batch_Info (company_id, sku, variant_code, batch_no)
select 
    company_id,
    No_,
    'dummy',
    'Ring Fenced'
from
    ext.Item
where
    (
        not exists (select 1 from ext.Item_Batch_Info where Item.company_id = Item_Batch_Info.company_id and Item.No_ = Item_Batch_Info.sku and variant_code = 'dummy' and batch_no = 'Ring Fenced')
    )
GO
