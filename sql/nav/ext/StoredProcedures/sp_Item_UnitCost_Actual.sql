CREATE procedure [ext].[sp_Item_UnitCost_Actual]
    (
        @fix_missing bit = 0,
        @fetch_next int = 5,
        @date date = null
    )

as

set nocount on

if @date is null set @date = getutcdate()

declare @x table (item_id int)

if @fix_missing = 1

    insert into @x (item_id)
    select distinct
        i.ID
    from
        ext.Item i
    join
        hs_consolidated.Item ii
    on
        (
            i.company_id = ii.company_id
        and i.No_ = ii.No_
        )
    where
        (
            i.company_id = 1
        and i.ID not in (select item_id from ext.Item_UnitCost_Actual where datediff(day,_date,@date) < 30)
        and ii.[Type] = 0
        and datediff(day,i.lastOrder,@date) < 30
        )

insert into @x (item_id)
select
    x.item_id
from
    ext.Item i
join
    hs_consolidated.Item ii
on
    (
        i.company_id = ii.company_id
    and i.No_ = ii.No_
    )
left join
    (
        select
            _date,
            datediff(day,_date,@date) last_update,
            item_id,
            case when lead(_date) over (partition by item_id order by _date) is null then 1 else 0 end is_current
        from
            ext.Item_UnitCost_Actual
    ) x
on
    (
        i.ID = x.item_id
    )
where
    (
        (
            x.is_current = 1
        or  x.item_id is null
        )
    and ii.[Type] = 0
    and i.lastOrder >= dateadd(day,-1,@date)
    and datediff(day,x._date,i.lastOrder) > 1
    )
order by
    x._date
offset 0 rows
fetch next @fetch_next rows only

delete from y from ext.Item_UnitCost_Actual y join @x x on (y._date = @date and y.item_id = x.item_id)

insert into ext.Item_UnitCost_Actual (_date, item_id, cost)
select
    @date,
    x.item_id,
    cost.cost
from
    @x x
cross apply
    ext.fn_Item_UnitCost_Actual(x.item_id,@date) cost
GO
