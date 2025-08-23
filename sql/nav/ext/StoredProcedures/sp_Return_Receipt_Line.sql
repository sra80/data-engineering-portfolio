create or alter procedure ext.sp_Return_Receipt_Line

as

set nocount on

while (select isnull(sum(1),0) from ext.Return_Receipt_Line where batch_id is null) > 0

begin

    ;with batch_info as
        (
            select
                ibi.company_id,
                sih.[Order No_] order_no,
                sil.[No_] item_no,
                ID batch_id
            from
                ext.Item_Batch_Info ibi
            join
                dbo.[UK$Item Ledger Entry] ile
            on
                (
                    ibi.company_id = 1
                and ibi.sku = ile.[Item No_]
                and ibi.batch_no = ile.[Lot No_]
                )
            join
                [dbo].[UK$Value Entry] ve
            on
                (
                    ile.[Entry No_] = ve.[Item Ledger Entry No_]
                )
            join
                [dbo].[UK$Sales Invoice Line] sil
            on
                (
                    ve.[Document No_] = sil.[Document No_]
                and ve.[Item No_] = sil.[No_]
                )
            join
                [dbo].[UK$Sales Invoice Header] sih
            on
                (
                    sih.[No_] = sil.[Document No_]
                )

            union all

            select
                ibi.company_id,
                sih.[Order No_] order_no,
                sil.[No_] item_no,
                ID batch_id
            from
                ext.Item_Batch_Info ibi
            join
                dbo.[NL$Item Ledger Entry] ile
            on
                (
                    ibi.company_id = 4
                and ibi.sku = ile.[Item No_]
                and ibi.batch_no = ile.[Lot No_]
                )
            join
                [dbo].[NL$Value Entry] ve
            on
                (
                    ile.[Entry No_] = ve.[Item Ledger Entry No_]
                )
            join
                [dbo].[NL$Sales Invoice Line] sil
            on
                (
                    ve.[Document No_] = sil.[Document No_]
                and ve.[Item No_] = sil.[No_]
                )
            join
                [dbo].[NL$Sales Invoice Header] sih
            on
                (
                    sih.[No_] = sil.[Document No_]
                )

            union all

            select
                ibi.company_id,
                sih.[Order No_] order_no,
                sil.[No_] item_no,
                ID batch_id
            from
                ext.Item_Batch_Info ibi
            join
                dbo.[NZ$Item Ledger Entry] ile
            on
                (
                    ibi.company_id = 5
                and ibi.sku = ile.[Item No_]
                and ibi.batch_no = ile.[Lot No_]
                )
            join
                [dbo].[NZ$Value Entry] ve
            on
                (
                    ile.[Entry No_] = ve.[Item Ledger Entry No_]
                )
            join
                [dbo].[NZ$Sales Invoice Line] sil
            on
                (
                    ve.[Document No_] = sil.[Document No_]
                and ve.[Item No_] = sil.[No_]
                )
            join
                [dbo].[NZ$Sales Invoice Header] sih
            on
                (
                    sih.[No_] = sil.[Document No_]
                )

            union all

            select
                ibi.company_id,
                sih.[Order No_] order_no,
                sil.[No_] item_no,
                ID batch_id
            from
                ext.Item_Batch_Info ibi
            join
                dbo.[IE$Item Ledger Entry] ile
            on
                (
                    ibi.company_id = 6
                and ibi.sku = ile.[Item No_]
                and ibi.batch_no = ile.[Lot No_]
                )
            join
                [dbo].[IE$Value Entry] ve
            on
                (
                    ile.[Entry No_] = ve.[Item Ledger Entry No_]
                )
            join
                [dbo].[IE$Sales Invoice Line] sil
            on
                (
                    ve.[Document No_] = sil.[Document No_]
                and ve.[Item No_] = sil.[No_]
                )
            join
                [dbo].[IE$Sales Invoice Header] sih
            on
                (
                    sih.[No_] = sil.[Document No_]
                )     

        )

    update
        sub_q
    set
        sub_q.dest_batch_id = sub_q.source_batch_id,
        sub_q.dest_sales_line_id = sub_q.source_sales_line_id
    from
        (
            select top 1000
                e_rrl.batch_id dest_batch_id,
                e_rrl.sales_line_id dest_sales_line_id,
                bi.sales_line_id source_sales_line_id,
                coalesce(bi.batch_id,bi_non.batch_id,-1) source_batch_id
            from
                ext.Return_Receipt_Line e_rrl
            join
                hs_consolidated.[Return Receipt Line] rrl
            on
                (
                    e_rrl.company_id = rrl.company_id
                and e_rrl.[Document No_] = rrl.[Document No_]
                and e_rrl.[Line No_] = rrl.[Line No_]
                )
            join
                hs_consolidated.[Return Receipt Header] rrh
            on
                (
                    e_rrl.company_id = rrh.company_id
                and e_rrl.[Document No_] = rrh.[No_]
                )
            outer apply
                (
                    select top 1
                        bi.batch_id,
                        isnull
                                (
                                    (
                                        select top 1
                                            id 
                                        from 
                                            ext.Sales_Line sl 
                                        where 
                                            (
                                                sl.company_id = bi.company_id
                                            and sl.[Document No_] = bi.order_no
                                            and sl.[No_] = bi.item_no
                                            )
                                    ),
                                    (
                                        select top 1
                                            id 
                                        from 
                                            ext.Sales_Line_Archive sla
                                        where 
                                            (
                                                sla.company_id = bi.company_id
                                            and sla.[Document No_] = bi.order_no
                                            and sla.[No_] = bi.item_no
                                            )
                                    )
                                ) sales_line_id
                    from
                        batch_info bi
                    where
                        (
                            bi.company_id = e_rrl.company_id
                        and bi.order_no = nullif(rrh.[Sales Order Reference],'')
                        and bi.item_no = rrl.No_
                        )
                ) bi
            outer apply
                (
                    select top 1
                        ibi.ID batch_id
                    from
                        ext.Item_Batch_Info ibi
                    where
                        (
                            ibi.company_id = e_rrl.company_id
                        and ibi.sku = rrl.[No_]
                        and ibi.variant_code = 'dummy'
                        and ibi.batch_no = 'Not Provided'
                        )
                ) bi_non
            where
                (
                    e_rrl.batch_id is null
                )
        ) sub_q

end