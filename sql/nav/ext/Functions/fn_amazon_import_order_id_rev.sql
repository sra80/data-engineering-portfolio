create or alter function ext.fn_amazon_import_order_id_rev
    (
        @amazon_order_id_p1 int,
        @amazon_order_id_p2 int,
        @amazon_order_id_p3 int
    )

returns nvarchar(32)

as

begin

return concat(format(@amazon_order_id_p1,replicate('0',3)),'-',format(@amazon_order_id_p2,replicate('0',7)),'-',format(@amazon_order_id_p3,replicate('0',7)))

end