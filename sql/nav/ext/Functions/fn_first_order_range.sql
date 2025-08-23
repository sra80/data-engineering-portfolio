create function ext.fn_first_order_range
    ( 
        @cus nvarchar(20), 
        @sku nvarchar(20)
    )

returns date

as

begin

declare @date date

select
    @date = min(first_order)
from
    ext.Customer_Item_Summary s
where
    (
        s.cus = @cus
    and s.sku in
        (
            select
                _collection.No_ sku
            from
                dbo.[UK$Item] base
            join
                dbo.[UK$Range] _range
            on
                (
                    base.[Range Code] = _range.Code
                )
            join
                dbo.[UK$Item] _collection
            on
                _range.Code = _collection.[Range Code]
            where
                (
                    base.No_ = @sku
                )
        )
    )

return @date

end
GO
