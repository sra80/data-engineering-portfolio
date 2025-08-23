CREATE   function [ext].[fn_Item_UnitCost_Actual]
    ( 
        @item_id int,
        @closing_date date = null
    )

returns table as

return
(
    with x as
        (
            select
                convert(bit,0) is_assembly,
                ibi.company_id,
                ibi.sku,
                ibi.variant_code,
                ibi.batch_no,
                open_entry.[Entry Type] entry_type,
                open_entry.[Document No_] doc_no,
                open_entry.[Quantity] qty,
                open_entry.cost
            from
                ext.Item_Batch_Info ibi
            join
                ext.Item i
            on
                (
                    ibi.company_id = i.company_id
                and ibi.sku = i.No_
                )
            outer apply
                (
                    select top 1
                        ile.[Entry Type],
                        ile.[Document No_],
                        ile.[Quantity],
                        ve.cost
                    from
                        [dbo].[UK$Item Ledger Entry] ile
                    cross apply
                        (
                            select sum(ve.[Cost Amount (Actual)])+sum(ve.[Cost Amount (Expected)]) cost from [UK$Value Entry] ve left join [UK$Purchase Line] pl on (ve.[Document No_] = pl.[Prod_ Order No_]) where isnull(pl.[Qty_ to Invoice],0) = 0 and ile.[Entry No_] = ve.[Item Ledger Entry No_] and convert(date,ve.[Posting Date]) <= isnull(@closing_date,getutcdate())
                        ) ve
                    where
                        (
                            ibi.company_id = 1
                        and ibi.sku = ile.[Item No_]
                        and ibi.variant_code = case when nullif(ile.[Lot No_],'') is null then 'dummy' else ile.[Variant Code] end
                        and ibi.batch_no = isnull(nullif(ile.[Lot No_],''),'Not Provided')
                        and ile.[Positive] = 1
                        and convert(date,ile.[Posting Date]) <= isnull(@closing_date,getutcdate())
                        )
                    order by
                        ile.[Entry No_]
                ) open_entry
            where
                (
                    i.ID = @item_id
                )

            union all

            select
                convert(bit,1) is_assembly,
                ibi.company_id,
                ibi.sku,
                ibi.variant_code,
                ibi.batch_no,
                open_entry.[Entry Type] entry_type,
                open_entry.[Document No_] doc_no,
                open_entry.[Quantity] qty,
                open_entry.cost
            from
                ext.Item_Batch_Info ibi
            join
                [dbo].[UK$BOM Component] bom
            on
                (
                    ibi.company_id = 1
                and ibi.sku = bom.No_
                )
            join
                ext.Item i
            on
                (
                    i.company_id = 1
                and bom.[Parent Item No_] = i.No_
                )
            outer apply
                (
                    select top 1
                        ile.[Entry Type],
                        ile.[Document No_],
                        ile.[Quantity],
                        ve.cost
                    from
                        [dbo].[UK$Item Ledger Entry] ile
                    cross apply
                        (
                            select sum(ve.[Cost Amount (Actual)])+sum(ve.[Cost Amount (Expected)]) cost from [UK$Value Entry] ve left join [UK$Purchase Line] pl on (ve.[Document No_] = pl.[Prod_ Order No_]) where isnull(pl.[Qty_ to Invoice],0) = 0 and ile.[Entry No_] = ve.[Item Ledger Entry No_] and convert(date,ve.[Posting Date]) <= isnull(@closing_date,getutcdate())
                        ) ve
                    where
                        (
                            ibi.company_id = 1
                        and ibi.sku = ile.[Item No_]
                        and ibi.variant_code = case when nullif(ile.[Lot No_],'') is null then 'dummy' else ile.[Variant Code] end
                        and ibi.batch_no = isnull(nullif(ile.[Lot No_],''),'Not Provided')
                        and ile.[Positive] = 1
                        and convert(date,ile.[Posting Date]) <= isnull(@closing_date,getutcdate())
                        )
                    order by
                        ile.[Entry No_]
                ) open_entry
            where
                (
                    i.ID = @item_id
                )
        )
    , y as
        (
            select
                x.company_id,
                x.sku,
                x.variant_code,
                x.batch_no,
                x.entry_type,
                x.doc_no,
                x.qty,
                open_entry.cost
            from
                x
            cross apply
                (
                    select
                        sum(0-db_sys.fn_divide(open_entry.cost,open_entry.Quantity,0)*ile_x.Quantity) cost
                    from
                        [dbo].[UK$Item Ledger Entry] ile_x
                    cross apply
                        (
                            select top 1
                                ile.[Entry Type],
                                ile.[Document No_],
                                ile.[Quantity],
                                ve.cost
                            from
                                [dbo].[UK$Item Ledger Entry] ile
                            cross apply
                                (
                                    select sum(ve.[Cost Amount (Actual)])+sum(ve.[Cost Amount (Expected)]) cost from [UK$Value Entry] ve left join [UK$Purchase Line] pl on (ve.[Document No_] = pl.[Prod_ Order No_]) where isnull(pl.[Qty_ to Invoice],0) = 0 and ile.[Entry No_] = ve.[Item Ledger Entry No_] and convert(date,ve.[Posting Date]) <= isnull(@closing_date,getutcdate())
                                ) ve
                            where
                                (
                                    ile_x.[Item No_] = ile.[Item No_]
                                and ile_x.[Variant Code] = ile.[Variant Code]
                                and ile_x.[Lot No_] = ile.[Lot No_]
                                and ile.[Positive] = 1
                                and convert(date,ile.[Posting Date]) <= isnull(@closing_date,getutcdate())
                                )
                            order by
                                ile.[Entry No_]
                        ) open_entry
                    where
                        (
                            ile_x.[Entry Type] = 5
                        and x.doc_no = ile_x.[Document No_]
                        )
                ) open_entry
            where
                (
                    x.entry_type = 6
                and x.cost is null
                )
        )
    , cost0 as
        (
            select
                round(sum(cost.cost),2) cost
            from
                (
                    select
                        db_sys.fn_divide(isnull(x.cost,y.cost),x.qty,0) * db_sys.fn_divide(stock.stock,sum(stock.stock) over (),0) cost
                    from
                        x
                    left join
                        y
                    on
                        (
                            x.company_id = y.company_id
                        and x.sku = y.sku
                        and x.variant_code = y.variant_code
                        and x.batch_no = y.batch_no
                        )
                    cross apply
                        (
                            select
                                sum(ile.Quantity) stock
                            from
                                [dbo].[UK$Item Ledger Entry] ile
                            where
                                (
                                    x.sku = ile.[Item No_]
                                and x.variant_code = ile.[Variant Code]
                                and x.batch_no = ile.[Lot No_]
                                and convert(date,ile.[Posting Date]) <= isnull(@closing_date,getutcdate())
                                )
                        ) stock
                    where
                        (
                            x.is_assembly = 0
                        and stock.stock > 0
                        )
                ) cost
        )
    , cost1 as
        (
            select
                round(sum(cost.cost),2) cost
            from
                (
                    select
                        db_sys.fn_divide(isnull(x.cost,y.cost),x.qty,0) * db_sys.fn_divide(x.qty,sum(x.qty) over (),0) cost
                    from
                        x
                    left join
                        y
                    on
                        (
                            x.company_id = y.company_id
                        and x.sku = y.sku
                        and x.variant_code = y.variant_code
                        and x.batch_no = y.batch_no
                        )
                    cross apply
                        (
                            select
                                sum(ile.Quantity) stock
                            from
                                [dbo].[UK$Item Ledger Entry] ile
                            where
                                (
                                    x.sku = ile.[Item No_]
                                and x.variant_code = ile.[Variant Code]
                                and x.batch_no = ile.[Lot No_]
                                and convert(date,ile.[Posting Date]) <= isnull(@closing_date,getutcdate())
                                )
                        ) stock
                    where
                        (
                            x.is_assembly = 0
                        )
                ) cost
        )
    , cost2 as
        (
            select
                round(sum(cost.cost),2) cost
            from
                (
                    select
                        db_sys.fn_divide(isnull(x.cost,y.cost),x.qty,0) * db_sys.fn_divide(stock.stock,sum(stock.stock) over (),0) cost
                    from
                        x
                    left join
                        y
                    on
                        (
                            x.company_id = y.company_id
                        and x.sku = y.sku
                        and x.variant_code = y.variant_code
                        and x.batch_no = y.batch_no
                        )
                    cross apply
                        (
                            select
                                sum(ile.Quantity) stock
                            from
                                [dbo].[UK$Item Ledger Entry] ile
                            where
                                (
                                    x.sku = ile.[Item No_]
                                and x.variant_code = ile.[Variant Code]
                                and x.batch_no = ile.[Lot No_]
                                and convert(date,ile.[Posting Date]) <= isnull(@closing_date,getutcdate())
                                )
                        ) stock
                    where
                        (
                            x.is_assembly = 1
                        and stock.stock > 0
                        )
                ) cost
        )
    , cost3 as
        (
            select
                round(sum(cost.cost),2) cost
            from
                (
                    select
                        db_sys.fn_divide(isnull(x.cost,y.cost),x.qty,0) * db_sys.fn_divide(x.qty,sum(x.qty) over (),0) cost
                    from
                        x
                    left join
                        y
                    on
                        (
                            x.company_id = y.company_id
                        and x.sku = y.sku
                        and x.variant_code = y.variant_code
                        and x.batch_no = y.batch_no
                        )
                    cross apply
                        (
                            select
                                sum(ile.Quantity) stock
                            from
                                [dbo].[UK$Item Ledger Entry] ile
                            where
                                (
                                    x.sku = ile.[Item No_]
                                and x.variant_code = ile.[Variant Code]
                                and x.batch_no = ile.[Lot No_]
                                and convert(date,ile.[Posting Date]) <= isnull(@closing_date,getutcdate())
                                )
                        ) stock
                    where
                        (
                            x.is_assembly = 1
                        )
                ) cost
        )

    select
        coalesce(cost0.cost,cost1.cost,cost2.cost,cost3.cost,0) cost
    from
        cost0, cost1, cost2, cost3

)
GO
