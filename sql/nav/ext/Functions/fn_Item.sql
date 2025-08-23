--ext.fn_Item

create   function ext.fn_Item
    (
        @company_id int,
        @sku nvarchar(40)
    )

returns int

as

begin

declare @item_ID int

select @item_ID = ID from ext.Item where company_id = @company_id and No_ = @sku

return @item_ID

end
GO
