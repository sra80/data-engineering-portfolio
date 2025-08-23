create or alter procedure [ext].[sp_Item_UnitCost]

as

set nocount on

declare @t table (item_ID int, row_version int, is_different bit, cost_actual float, cost_forecast float)

declare @company_id int, @item_id int, @sku nvarchar(20), @row_version int, @is_different bit, @change_count int = 0, @cost_actual float, @cost_forecast float, @prod_ord_ref nvarchar(20), @location nvarchar(20), @child_sku nvarchar(20), @recipe_qty float, @child_qty float, @place_holder uniqueidentifier, @auditLog_ID int, @error_message nvarchar(max) = '', @count_fail int = 0, @bodyIntro nvarchar(max), @bodyOutro nvarchar(max) = ''

select top 1 @place_holder = place_holder from db_sys.procedure_schedule where procedureName = 'ext.sp_Item_UnitCost' and process_active = 1

select @auditLog_ID = ID from db_sys.auditLog where place_holder = @place_holder

declare [844d0cc2-e0a2-4d9e-89e9-4fa57aea178e] cursor for
select
    e.company_id,
    e.ID,
    e.No_,
    1,
    -1,
    null,
    null,
    null,
    null,
    null,
    null,
    null
from
    ext.Item e
join
    hs_consolidated.Item d
on
    (
        e.company_id = d.company_id
    and e.No_ = d.No_
    )
where
    (
        d.[Status] in (0,1,4)
    and d.[Inventory Posting Group] in ('FINISHED','B2B ITEMS')
    )

open [844d0cc2-e0a2-4d9e-89e9-4fa57aea178e]

fetch next from [844d0cc2-e0a2-4d9e-89e9-4fa57aea178e] into @company_id, @item_id, @sku, @is_different, @row_version, @cost_actual, @cost_forecast, @prod_ord_ref, @location, @child_sku, @recipe_qty, @child_qty

while @@fetch_status = 0

begin /*09fd*/

        begin try /*7fa6*/

            --@cost_actual
            select
                @cost_actual = sum(cost_ratio_split)
            from
                (
                    select
                        db_sys.fn_divide(stock_in.cost,stock_in.Quantity,0)*
                        db_sys.fn_divide(balance.qty,sum(balance.qty) over (),0) cost_ratio_split --splits cost by balance of stock per batch, more stock means batch carries more weight in unit cost
                    from
                        hs_consolidated.[Lot No_ Information] lni
                    cross apply
                        (
                            select top 10000
                                ile.Quantity,
                                ve.cost
                            from
                                hs_consolidated.[Item Ledger Entry] ile
                            join
                                ext.Location loc
                            on
                                (
                                    ile.company_id = loc.company_id
                                and ile.[Location Code] = loc.location_code
                                )
                            cross apply
                                (
                                    select sum(ve.[Cost Amount (Actual)])+sum(ve.[Cost Amount (Expected)]) cost from hs_consolidated.[Value Entry] ve left join hs_consolidated.[Purchase Line] pl on (ve.company_id = pl.company_id and ve.[Document No_] = pl.[Prod_ Order No_]) where isnull(pl.[Qty_ to Invoice],0) = 0 and ile.company_id = ve.company_id and ile.[Entry No_] = ve.[Item Ledger Entry No_]

                                ) ve
                            where
                                (
                                    lni.company_id = @company_id
                                and ile.[Item No_] = @sku
                                and lni.company_id = ile.company_id
                                and lni.[Item No_] = ile.[Item No_]
                                and lni.[Lot No_] = ile.[Lot No_]
                                and ile.[Entry Type] in (0,2,4,6,9)
                                and ve.cost > 0
                                -- and loc.distribution_type = 'DIRECT'
                                )
                            order by
                                ile.[Entry Type]
                        ) stock_in
                    join
                        (
                            select
                                -- loc.distribution_type,
                                ile.[Lot No_] batchNo,
                                sum(ile.Quantity) qty
                            from
                                hs_consolidated.[Item Ledger Entry] ile
                            join
                                ext.Location loc
                            on
                                (
                                    ile.company_id = loc.company_id
                                and ile.[Location Code] = loc.location_code
                                )
                            where
                                (
                                    ile.company_id = @company_id
                                and ile.[Item No_] = @sku
                                -- and loc.distribution_type = 'DIRECT' --in ('DIRECT','3PMKTPL')
                                )
                            group by
                                -- loc.distribution_type,
                                ile.[Lot No_]
                            having
                                sum(ile.Quantity) > 0
                        ) balance
                    on
                        (
                            lni.[Lot No_] = balance.batchNo
                        )
                    where
                        (
                            lni.company_id = @company_id
                        and lni.[Item No_] = @sku
                        )
                ) actual_unit_cost

            if @cost_actual is null

            begin /*afa3*/

                select top 1 @prod_ord_ref = nullif([Prod_ Order No_],''), @cost_actual = [Unit Cost (LCY)] from hs_consolidated.[Purchase Line] where company_id = @company_id and No_ = @sku and [Outstanding Amount] = 0

                select top 1 @location = [Location Code] from hs_consolidated.[Prod_ Order Line] where company_id = @company_id and [Prod_ Order No_] = @prod_ord_ref

                ;with poc1 as
                    (
                    select
                        poc_0.company_id,
                        poc_0.[Prod_ Order No_] prod_order_ref,
                        poc_0.[Item No_] sku,
                        poc_0.[Quantity] recipe_qty,
                        x.unit_cost,
                        x.prod_order_ref_child
                    from
                        (
                            select
                                company_id,
                                [Prod_ Order No_],
                                [Item No_],
                                [Quantity]
                            from
                                hs_consolidated.[Prod_ Order Component]
                        ) poc_0
                    cross apply
                        (
                            select top 1
                                children.unit_cost,
                                children.prod_order_ref_child
                            from
                        (
                            select
                                stock._order,
                                stock.qty,
                                db_sys.fn_divide(ve.cost,qty_in.qty_in,0) unit_cost,
                                null prod_order_ref_child
                            from
                                (
                                select
                                    row_number() over (order by qty desc) - case when company_id = @company_id and _location = @location then 9999 else 0 end _order,
                                    company_id,
                                    _location,
                                    qty
                                from
                                    (
                                    select
                                        ile.company_id,
                                        ile.[Location Code] _location,
                                        sum(ile.[Quantity]) qty
                                    from
                                        hs_consolidated.[Item Ledger Entry] ile
                                    join
                                        ext.Location loc
                                    on
                                        (
                                            ile.company_id = loc.company_id
                                        and ile.[Location Code] = loc.location_code
                                        )
                                    where
                                        (
                                            ile.company_id = poc_0.company_id
                                        and ile.[Item No_] = poc_0.[Item No_]
                                        and
                                            (
                                                loc.holding_loc = 1
                                            or  loc.distribution_loc = 1
                                            )
                                        )
                                    group by
                                        ile.company_id,
                                        ile.[Location Code]
                                    ) sub_query
                                ) stock
                            outer apply
                                (
                                    select
                                        max([Entry No_]) last_entry
                                    from
                                        hs_consolidated.[Item Ledger Entry] ile
                                    where
                                        (
                                            stock.company_id = ile.company_id
                                        and stock._location = ile.[Location Code]
                                        and ile.[Item No_] = poc_0.[Item No_]
                                        and ile.[Entry Type] in (0,6)
                                        )
                                ) last_stock_in
                            outer apply
                                (
                                    select
                                        max(ile.[Entry No_]) last_entry
                                    from
                                        hs_consolidated.[Item Ledger Entry] ile
                                    where
                                        (
                                            stock.company_id = ile.company_id
                                        and stock._location = ile.[Location Code]
                                        and ile.[Item No_] = poc_0.[Item No_]
                                        and ile.[Entry Type] in (2)
                                        )
                                ) last_stock_adj
                            cross apply
                                (
                                    select
                                        ile.Quantity qty_in
                                    from
                                        hs_consolidated.[Item Ledger Entry] ile
                                    where
                                        (
                                            ile.company_id = @company_id
                                        and isnull(last_stock_in.last_entry,last_stock_adj.last_entry) = ile.[Entry No_]
                                        )
                                ) qty_in
                            cross apply
                                (
                                    select
                                        sum(ve.[Cost Amount (Actual)])+sum(ve.[Cost Amount (Expected)]) cost
                                    from
                                        hs_consolidated.[Value Entry] ve
                                    where
                                        (
                                            ve.company_id = @company_id
                                        and isnull(last_stock_in.last_entry,last_stock_adj.last_entry) = ve.[Item Ledger Entry No_]
                                        )
                                ) ve

                            union all

                            select
                                case when pl.company_id = @company_id and pl.[Location Code] = @location then 9998 else 9999 end _order,
                                pl.[Outstanding Amount],
                                pl.[Unit Cost (LCY)],
                                pl.[Prod_ Order No_]
                            from
                                hs_consolidated.[Purchase Line] pl
                            where
                                (
                                    pl.company_id = poc_0.company_id
                                and pl.No_ = poc_0.[Item No_]
                                and pl.[Outstanding Amount] > 0
                                )
                        ) children
                    where
                        (
                            db_sys.fn_divide(children.qty,poc_0.Quantity,0) >= 0.75
                        )
                    order by
                        children._order
                    ) x

                    )

                , poc2 as
                    (
                        select
                            poc1.company_id,
                            poc1.prod_order_ref,
                            poc1.prod_order_ref_child,
                            poc1.sku,
                            convert(float,poc1.recipe_qty) recipe_qty,
                            poc1.unit_cost
                        from
                            poc1
                        where
                            (
                                poc1.company_id = @company_id
                            and poc1.prod_order_ref = @prod_ord_ref
                            )

                        union all

                        select
                            poc1.company_id,
                            poc1.prod_order_ref,
                            poc1.prod_order_ref_child,
                            poc1.sku,
                            poc1.recipe_qty*poc2.recipe_qty,
                            poc1.unit_cost
                        from
                            poc1
                        cross apply
                            poc2
                        where
                            (
                                poc1.company_id = poc2.company_id
                            and poc1.prod_order_ref = poc2.prod_order_ref_child
                            )
                    )

                select @cost_actual += (recipe_qty*unit_cost) from poc2

                select @prod_ord_ref = null, @location = null

            end /*afa3*/

            --@cost_forecast
            select top 1 @prod_ord_ref = nullif([Prod_ Order No_],''), @cost_forecast = [Unit Cost (LCY)] from hs_consolidated.[Purchase Line] where company_id = @company_id and No_ = @sku and [Outstanding Amount] > 0

            select top 1 @location = [Location Code] from hs_consolidated.[Prod_ Order Line] where company_id = @company_id and [Prod_ Order No_] = @prod_ord_ref

            ;with poc1 as
                (
                select
                    poc_0.company_id,
                    poc_0.[Prod_ Order No_] prod_order_ref,
                    poc_0.[Item No_] sku,
                    poc_0.[Quantity] recipe_qty,
                    x.unit_cost,
                    x.prod_order_ref_child
                from
                    (
                        select
                            poc.company_id,
                            poc.[Prod_ Order No_],
                            poc.[Item No_],
                            poc.[Quantity]
                        from
                            hs_consolidated.[Prod_ Order Component] poc
                        join
                            hs_consolidated.[Prod_ Order Line] pol
                        on
                            (
                                poc.[Prod_ Order No_] = pol.[Prod_ Order No_]
                            )
                        where
                            (
                                poc.[Item No_] != pol.[Item No_]
                            )
                    ) poc_0
                cross apply
                    (
                        select top 1
                            children.unit_cost,
                            children.prod_order_ref_child
                        from
                            (
                                select
                                    stock._order,
                                    stock.qty,
                                    db_sys.fn_divide(ve.cost,qty_in.qty_in,0) unit_cost,
                                    null prod_order_ref_child
                                from
                                    (
                                    select
                                        company_id,
                                        row_number() over (order by qty desc) - case when _location = @location then 9999 else 0 end _order,
                                        _location,
                                        qty
                                    from
                                        (
                                        select
                                            ile.company_id,
                                            ile.[Location Code] _location,
                                            sum(ile.[Quantity]) qty
                                        from
                                            hs_consolidated.[Item Ledger Entry] ile
                                        join
                                            ext.Location loc
                                        on
                                            (
                                                ile.company_id = loc.company_id
                                            and ile.[Location Code] = loc.location_code
                                            )
                                        where
                                            (
                                                ile.company_id = poc_0.company_id
                                            and ile.[Item No_] = poc_0.[Item No_]
                                            and
                                                (
                                                    loc.holding_loc = 1
                                                or  loc.distribution_loc = 1
                                                )
                                            )
                                        group by
                                            ile.company_id,
                                            ile.[Location Code]
                                        ) sub_query
                                    ) stock
                                outer apply
                                    (
                                        select
                                            max([Entry No_]) last_entry
                                        from
                                            hs_consolidated.[Item Ledger Entry] ile
                                        where
                                            (
                                                stock.company_id = ile.company_id
                                            and stock._location = ile.[Location Code]
                                            and ile.[Item No_] = poc_0.[Item No_]
                                            and ile.[Entry Type] in (0,6)
                                            )
                                    ) last_stock_in
                                outer apply
                                    (
                                        select
                                            max(ile.[Entry No_]) last_entry
                                        from
                                            hs_consolidated.[Item Ledger Entry] ile
                                        where
                                            (
                                                stock.company_id = ile.company_id
                                            and stock._location = ile.[Location Code]
                                            and ile.[Item No_] = poc_0.[Item No_]
                                            and ile.[Entry Type] in (2)
                                            )
                                    ) last_stock_adj
                                cross apply
                                    (
                                        select
                                            ile.Quantity qty_in
                                        from
                                            hs_consolidated.[Item Ledger Entry] ile
                                        where
                                            (
                                                ile.company_id = @company_id
                                            and isnull(last_stock_in.last_entry,last_stock_adj.last_entry) = ile.[Entry No_]
                                            )
                                    ) qty_in
                                cross apply
                                    (
                                        select
                                            sum(ve.[Cost Amount (Actual)])+sum(ve.[Cost Amount (Expected)]) cost
                                        from
                                            hs_consolidated.[Value Entry] ve
                                        where
                                            (
                                                ve.company_id = @company_id
                                            and isnull(last_stock_in.last_entry,last_stock_adj.last_entry) = ve.[Item Ledger Entry No_]
                                            )
                                    ) ve

                                union all

                                select
                                    case when pl.company_id = @company_id and pl.[Location Code] = @location then 9998 else 9999 end _order,
                                    pl.[Outstanding Amount],
                                    pl.[Unit Cost (LCY)],
                                    pl.[Prod_ Order No_]
                                from
                                    hs_consolidated.[Purchase Line] pl
                                where
                                    (
                                        pl.company_id = poc_0.company_id
                                    and pl.No_ = poc_0.[Item No_]
                                    and pl.[Outstanding Amount] > 0
                                    )
                            ) children
                where
                    (
                        db_sys.fn_divide(children.qty,poc_0.Quantity,0) >= 0.75
                    )
                order by
                    children._order
                ) x

                )
                

            , poc2 as
                (
                    select
                        poc1.company_id,
                        poc1.prod_order_ref,
                        prod_order_ref_child,
                        poc1.sku,
                        convert(float,poc1.recipe_qty) recipe_qty,
                        poc1.unit_cost
                    from
                        poc1
                    where
                        (
                            company_id = @company_id
                        and prod_order_ref = @prod_ord_ref
                        )

                    union all

                    select
                        poc1.company_id,
                        poc1.prod_order_ref,
                        poc1.prod_order_ref_child,
                        poc1.sku,
                        poc1.recipe_qty*poc2.recipe_qty,
                        poc1.unit_cost
                    from
                        poc1
                    cross apply
                        poc2
                    where
                        (
                            poc1.company_id = poc2.company_id
                        and poc1.prod_order_ref = poc2.prod_order_ref_child
                        )
                )

            select @cost_forecast += (recipe_qty*unit_cost) from poc2

            set @cost_actual = ext.fn_Convert_Currency_GBP(@cost_actual,@company_id,getdate())
            set @cost_forecast = ext.fn_Convert_Currency_GBP(@cost_forecast,@company_id,getdate())

            set @cost_actual = round(isnull(@cost_actual,0),3)
            set @cost_forecast = round(isnull(@cost_forecast,0),3)

            select 
                @row_version = row_version,
                @is_different = 
                    case when 
                            @cost_actual=cost_actual
                        and
                            @cost_forecast=cost_forecast
                    then 0 else 1 end,
                @change_count += 
                    case when 
                            @cost_actual=cost_actual
                        and
                            @cost_forecast=cost_forecast
                    then 0 else 1 end 
            from 
                ext.Item_UnitCost 
            where 
                (
                    item_ID = @item_id
                and is_current = 1
                )

            insert into @t (item_ID, row_version, is_different, cost_actual, cost_forecast) values (@item_id, @row_version, @is_different, isnull(@cost_actual,0), isnull(@cost_forecast,0))

        end try /*7fa6*/

        begin catch

        set @count_fail += 1

        set @error_message += concat('<li>',@sku,' - ')

        set @error_message += concat(error_message(),'</li>')

        end catch

    fetch next from [844d0cc2-e0a2-4d9e-89e9-4fa57aea178e] into @company_id, @item_id, @sku, @is_different, @row_version, @cost_actual, @cost_forecast, @prod_ord_ref, @location, @child_sku, @recipe_qty, @child_qty

end /*09fd*/

close [844d0cc2-e0a2-4d9e-89e9-4fa57aea178e]
deallocate [844d0cc2-e0a2-4d9e-89e9-4fa57aea178e]

if @count_fail > 0

    begin

        set @bodyIntro = concat(@count_fail,' error',case when @count_fail > 1 then 's' else '' end,' occured while executing the procedure ext.sp_Item_UnitCost. Please see as follows:<ul>',@error_message,'</ul>')

        if @change_count > 0 set @bodyOutro = concat('Although issues were encountered, the unit cost price on ',@change_count,' item',case when @change_count = 1 then ' was' else 's were' end,' successfully updated.')

        exec db_sys.sp_email_notifications
            @subject = 'Error Executing ext.sp_Item_UnitCost',
            @bodyIntro = @bodyIntro,
            @bodyOutro = @bodyOutro,
            @auditLog_ID = @auditLog_ID,
            @is_team_alert = 1,
            @tnc_id = 6,
            @place_holder = @place_holder

    end

update
    u
set
    reviewedTSUTC = sysdatetime()
from
    @t t
join
    ext.Item_UnitCost u
on
    (
        t.item_ID = u.item_ID
    and u.row_version = t.row_version
    and u.is_current = 1
    and t.is_different = 0
    )

update 
    u
set
    reviewedTSUTC = sysdatetime(),
    is_current = 0
from
    @t t
join
    ext.Item_UnitCost u
on
    (
        t.item_ID = u.item_ID
    and u.row_version = t.row_version
    and u.is_current = 1
    and t.is_different = 1
    )

insert into ext.Item_UnitCost (item_ID, row_version, is_current, cost_actual, cost_forecast)
select
    t.item_ID,
    t.row_version+1,
    1,
    t.cost_actual,
    t.cost_forecast
from
    @t t
where
    (
        t.is_different = 1
    )
GO
