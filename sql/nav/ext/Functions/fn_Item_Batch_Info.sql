create function ext.fn_Item_Batch_Info
    (
        @company_id int,
        @sku nvarchar(20),
        @variant_code nvarchar(10),
        @batch_no nvarchar(20)
    )

returns int

as

begin

declare @batch_ID int

select @batch_ID = ID from ext.Item_Batch_Info where company_id = @company_id and sku = @sku and variant_code = @variant_code and batch_no = @batch_no

if @batch_ID is null select @batch_ID = ID from ext.Item_Batch_Info where company_id = @company_id and sku = @sku and variant_code = 'dummy' and batch_no = 'Not Provided'

return @batch_ID

end
GO
