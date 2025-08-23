create or alter function ext.fn_Item_UnitCost
    (
        @item_id int,
        @date date = null
    )

returns money

as

begin

declare @item_cost money

select @date = min(x.x) from (values (dateadd(millisecond,86399999,convert(datetime2(3),@date))),(getutcdate())) as x(x)

select
    @item_cost = sum(cost_price)
from
    (
        select top 1
            convert(money,round(uc.cost_actual,2)) cost_price
        from
            ext.Item_UnitCost uc
        where
            (
                uc.item_ID = @item_id
            and uc.reviewedTSUTC <= @date
            )
        order by
            uc.reviewedTSUTC desc

        union all

        select
            cost.cost_price
        from
            ext.Item i
        join
            [hs_consolidated].[BOM Component] bc
        on
            (
                i.company_id = bc.company_id
            and i.No_ = bc.[Parent Item No_]
            )
        join
            ext.Item ic
        on
            (
                bc.company_id = ic.company_id
            and bc.No_ = ic.No_
            )
        cross apply
            (
                select top 1
                    convert(money,round(uc.cost_actual,2)) cost_price
                from
                    ext.Item_UnitCost uc
                where
                    (
                        uc.item_ID = ic.ID
                    and uc.reviewedTSUTC <= @date
                    )
                order by
                    uc.reviewedTSUTC desc
            ) cost
        where
            (
                i.ID = @item_id
            )
    ) x

return @item_cost

end