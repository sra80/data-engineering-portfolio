create or alter function ext.fn_item_sku
    (
        @item_id int
    )

returns table

as

return

select company_id, No_ from ext.Item where ID = @item_id