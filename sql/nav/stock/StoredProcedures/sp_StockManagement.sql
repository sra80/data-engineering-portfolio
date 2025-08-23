create or alter procedure [stock].[sp_StockManagement]
    (
        @partition int = null,
        @rebuild_period date = null
    )

as

if @rebuild_period is not null set @partition = null

declare @eomonth date, @fomonth date, @datefrom date

if @partition >= 0 set @eomonth = eomonth(dateadd(month,-@partition,getutcdate()))

if @rebuild_period between datefromparts(year(getutcdate())-2,1,1) and getutcdate() set @eomonth = eomonth(@rebuild_period)

set @fomonth = dateadd(day,1,eomonth(@eomonth,-1))

if @partition >= 0

    begin

        insert ext.Item_Ledger_Entry (company_id, ile_entry_no, country_id, value_entry_original)
        select
            1,
            [Entry No_],
            case when ile.[Document Type] in (0,1) then null else -1 end,
            v.value_entry_original
        from
            [dbo].[UK$Item Ledger Entry] ile
        left join
            ext.Item_Ledger_Entry e_ile
        on
            (
                e_ile.company_id = 1
            and ile.[Entry No_] = e_ile.ile_entry_no
            )
        cross apply
            (
                select top 1
                    [Entry No_] value_entry_original
                from
                    [dbo].[UK$Value Entry] ve
                where
                    (
                        ile.[Entry No_] = ve.[Item Ledger Entry No_]
                    )
                order by
                    [Entry No_]
            ) v
        where
            (
                ile.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
            and e_ile.company_id is null
            and e_ile.ile_entry_no is null
            )

        insert ext.Item_Ledger_Entry (company_id, ile_entry_no, country_id, value_entry_original)
        select
            4,
            [Entry No_],
            -1,
            v.value_entry_original
        from
            [dbo].[NL$Item Ledger Entry] ile
        left join
            ext.Item_Ledger_Entry e_ile
        on
            (
                e_ile.company_id = 4
            and ile.[Entry No_] = e_ile.ile_entry_no
            )
        cross apply
            (
                select top 1
                    [Entry No_] value_entry_original
                from
                    [dbo].[NL$Value Entry] ve
                where
                    (
                        ile.[Entry No_] = ve.[Item Ledger Entry No_]
                    )
                order by
                    [Entry No_]
            ) v
        where
            (
                ile.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
            and e_ile.company_id is null
            and e_ile.ile_entry_no is null
            )

        insert ext.Item_Ledger_Entry (company_id, ile_entry_no, country_id, value_entry_original)
        select
            5,
            [Entry No_],
            -1,
            v.value_entry_original
        from
            [dbo].[NZ$Item Ledger Entry] ile
        left join
            ext.Item_Ledger_Entry e_ile
        on
            (
                e_ile.company_id = 5
            and ile.[Entry No_] = e_ile.ile_entry_no
            )
        cross apply
            (
                select top 1
                    [Entry No_] value_entry_original
                from
                    [dbo].[NZ$Value Entry] ve
                where
                    (
                        ile.[Entry No_] = ve.[Item Ledger Entry No_]
                    )
                order by
                    [Entry No_]
            ) v
        where
            (
                ile.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
            and e_ile.company_id is null
            and e_ile.ile_entry_no is null
            )

        insert into ext.Item_Ledger_Entry (company_id, ile_entry_no, country_id, value_entry_original)
        select
            6,
            [Entry No_],
            case when ile.[Document Type] in (0,1) then null else -1 end,
            v.value_entry_original
        from
            [dbo].[IE$Item Ledger Entry] ile
        left join
            ext.Item_Ledger_Entry e_ile
        on
            (
                e_ile.company_id = 6
            and ile.[Entry No_] = e_ile.ile_entry_no
            )
        cross apply
            (
                select top 1
                    [Entry No_] value_entry_original
                from
                    [dbo].[IE$Value Entry] ve
                where
                    (
                        ile.[Entry No_] = ve.[Item Ledger Entry No_]
                    )
                order by
                    [Entry No_]
            ) v
        where
            (
                ile.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
            and e_ile.company_id is null
            and e_ile.ile_entry_no is null
            )

    end

if @partition <= 5 or @rebuild_period between datefromparts(year(getutcdate())-2,1,1) and getutcdate()

    begin

        delete from stock.StockManagement_Archive where key_posting_date between @fomonth and @eomonth

        insert into stock.StockManagement_Archive (company_id, country_id, key_posting_date, opt_key, is_amazon, key_DocumentType, key_location, key_batch, Quantity, [Cost Actual], [Cost Expected], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount])
        select
            d.company_id,
            isnull(e.country_id,-1),
            d.key_posting_date,
            d.opt_key + case when d.ve_entry_no = e.value_entry_original then 1 else 2 end opt_key,
            d.is_amazon,
            d.key_DocumentType,
            isnull(d.key_location,(select top 1 ID from ext.Location l where d.company_id = l.company_id and l.default_loc = 1)) key_location,
            d.key_batch,
            isnull(sum(case when d.ve_entry_no = e.value_entry_original then d.Quantity else 0 end),0) Quantity,
            isnull(sum(d.[Cost Actual]),0) [Cost Actual],
            isnull(sum(d.[Cost Expected]),0) [Cost Expected],
            isnull(sum(d.[Cost Posted to G_L]),0) [Cost Posted to G_L],
            isnull(sum(d.[Sales Amount (Actual)]),0) [Sales Amount (Actual)],
            isnull(sum([Discount Amount]),0) [Discount Amount]
        from
            (
                select
                    ile.company_id,
                    ile.[Entry No_] ile_entry_no,
                    ve.[Entry No_] ve_entry_no,
                    convert(date,ve.[Posting Date]) key_posting_date,
                    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end opt_key,
                    case when amz.warehouse is null then 0 else 1 end is_amazon,
                    case when sih.[Sell-to Customer No_] in  (select cus_code from finance.SalesInvoices_Amazon) or amz.warehouse is not null then 1001 else ve.[Document Type] end key_DocumentType,
                    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
                    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
                    ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
                    ile.Quantity,
                    ve.[Cost Actual],
                    ve.[Cost Expected],
                    ve.[Cost Posted to G_L],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 and amz.warehouse is not null then db_sys.fn_divide(ve.[Sales Amount (Actual)],vat.vat_rate,default) else ve.[Sales Amount (Actual)] end [Sales Amount (Actual)],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
                from
                    (select 1 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[UK$Item Ledger Entry]) ile
                join 
                    (
                        select
                            ve.company_id,
                            [Item Ledger Entry No_] ileNo,
                            [Entry No_],
                            [Posting Date],
                            [Document Type],
                            [Document No_],
                            [Document Line No_],
                            [Adjustment],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                        from
                            (select 1 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[UK$Value Entry] where convert(date,[Posting Date]) between @fomonth and @eomonth) ve
                    ) ve
                on
                    (
                        ile.company_id = ve.company_id
                    and ile.[Entry No_] = ve.ileNo
                    )
                left join
                    finance.SalesInvoices_Amazon amz
                on
                    (
                        ile.company_id = 1
                    and ile.[Location Code] = amz.warehouse
                    )
                left join
                    [dbo].[UK$Customer] amz_c
                on
                    (
                        amz.cus_code = amz_c.No_
                    )
                left join
                    (select 1 company_id, [Document No_], [Line No_], [Promotion Discount Amount] from [dbo].[UK$Sales Invoice Line]) sil
                on
                    (
                        ve.company_id = sil.company_id
                    and ve.[Document No_] = sil.[Document No_] 
                    and ve.[Document Line No_] = sil.[Line No_]
                    and ve.[Adjustment] = 0
                    )
                left join
                    (select 1 company_id, [No_], [Sell-to Customer No_], [Currency Factor] from [dbo].[UK$Sales Invoice Header]) sih
                on 
                    (
                        ve.company_id = sih.company_id
                    and ve.[Document No_] = sih.[No_]
                    )
                left join
                    (
                    select
                        1 company_id,
                        i.[No_],
                        v.[VAT Bus_ Posting Group],
                        (v.[VAT _]/100)+1 vat_rate
                    from
                        [dbo].[UK$Item] i 
                    join
                        [dbo].[UK$VAT Posting Setup] v
                    on
                        (
                            i.[VAT Prod_ Posting Group] = v.[VAT Prod_ Posting Group]
                        )
                    ) vat 
                on
                    (
                        ile.company_id = vat.company_id
                    and ile.[Item No_] = vat.[No_]
                    and amz_c.[VAT Bus_ Posting Group] = vat.[VAT Bus_ Posting Group]
                    )

                union all

                select
                    ile.company_id,
                    ile.[Entry No_] ile_entry_no,
                    ve.[Entry No_] ve_entry_no,
                    convert(date,ve.[Posting Date]) key_posting_date,
                    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end opt_key,
                    0 is_amazon,
                    ve.[Document Type] key_DocumentType,
                    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
                    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
                    ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
                    ile.Quantity,
                    ve.[Cost Actual],
                    ve.[Cost Expected],
                    ve.[Cost Posted to G_L],
                    ve.[Sales Amount (Actual)],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
                from
                    (select 4 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[NL$Item Ledger Entry]) ile
                join 
                    (
                        select
                            ve.company_id,
                            [Item Ledger Entry No_] ileNo,
                            [Entry No_],
                            [Posting Date],
                            [Document Type],
                            [Document No_],
                            [Document Line No_],
                            [Adjustment],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                        from
                            (select 4 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[NL$Value Entry] where convert(date,[Posting Date]) between @fomonth and @eomonth) ve
                    ) ve
                on
                    (
                        ile.company_id = ve.company_id
                    and ile.[Entry No_] = ve.ileNo
                    )
                left join
                    (select 4 company_id, [Document No_], [Line No_], [Promotion Discount Amount] from [dbo].[NL$Sales Invoice Line]) sil
                on
                    (
                        ve.company_id = sil.company_id
                    and ve.[Document No_] = sil.[Document No_] 
                    and ve.[Document Line No_] = sil.[Line No_]
                    and ve.[Adjustment] = 0
                    )
                left join
                    (select 4 company_id, [No_], [Sell-to Customer No_], [Currency Factor] from [dbo].[NL$Sales Invoice Header]) sih
                on 
                    (
                        ve.company_id = sih.company_id
                    and ve.[Document No_] = sih.[No_]
                    )


                union all

                select
                    ile.company_id,
                    ile.[Entry No_] ile_entry_no,
                    ve.[Entry No_] ve_entry_no,
                    convert(date,ve.[Posting Date]) key_posting_date,
                    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end opt_key,
                    0 is_amazon,
                    ve.[Document Type] key_DocumentType,
                    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
                    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
                    ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
                    ile.Quantity,
                    ve.[Cost Actual],
                    ve.[Cost Expected],
                    ve.[Cost Posted to G_L],
                    ve.[Sales Amount (Actual)],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
                from
                    (select 5 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[NZ$Item Ledger Entry]) ile
                join 
                    (
                        select
                            ve.company_id,
                            [Item Ledger Entry No_] ileNo,
                            [Entry No_],
                            [Posting Date],
                            [Document Type],
                            [Document No_],
                            [Document Line No_],
                            [Adjustment],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                        from
                            (select 5 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[NZ$Value Entry] where convert(date,[Posting Date]) between @fomonth and @eomonth) ve
                    ) ve
                on
                    (
                        ile.company_id = ve.company_id
                    and ile.[Entry No_] = ve.ileNo
                    )
                left join
                    (select 5 company_id, [Document No_], [Line No_], [Promotion Discount Amount] from [dbo].[NZ$Sales Invoice Line]) sil
                on
                    (
                        ve.company_id = sil.company_id
                    and ve.[Document No_] = sil.[Document No_] 
                    and ve.[Document Line No_] = sil.[Line No_]
                    and ve.[Adjustment] = 0
                    )
                left join
                    (select 5 company_id, [No_], [Sell-to Customer No_], [Currency Factor] from [dbo].[NZ$Sales Invoice Header]) sih
                on 
                    (
                        ve.company_id = sih.company_id
                    and ve.[Document No_] = sih.[No_]
                    )

                union all

                select
                    ile.company_id,
                    ile.[Entry No_] ile_entry_no,
                    ve.[Entry No_] ve_entry_no,
                    convert(date,ve.[Posting Date]) key_posting_date,
                    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end opt_key,
                    0 is_amazon,
                    ve.[Document Type] key_DocumentType,
                    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
                    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
                    ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
                    ile.Quantity,
                    ve.[Cost Actual],
                    ve.[Cost Expected],
                    ve.[Cost Posted to G_L],
                    ve.[Sales Amount (Actual)],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
                from
                    (select 6 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[IE$Item Ledger Entry]) ile
                join 
                    (
                        select
                            ve.company_id,
                            [Item Ledger Entry No_] ileNo,
                            [Entry No_],
                            [Posting Date],
                            [Document Type],
                            [Document No_],
                            [Document Line No_],
                            [Adjustment],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                        from
                            (select 6 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[IE$Value Entry] where convert(date,[Posting Date]) between @fomonth and @eomonth) ve
                    ) ve
                on
                    (
                        ile.company_id = ve.company_id
                    and ile.[Entry No_] = ve.ileNo
                    )
                left join
                    (select 6 company_id, [Document No_], [Line No_], [Promotion Discount Amount] from [dbo].[IE$Sales Invoice Line]) sil
                on
                    (
                        ve.company_id = sil.company_id
                    and ve.[Document No_] = sil.[Document No_] 
                    and ve.[Document Line No_] = sil.[Line No_]
                    and ve.[Adjustment] = 0
                    )
                left join
                    (select 6 company_id, [No_], [Sell-to Customer No_], [Currency Factor] from [dbo].[IE$Sales Invoice Header]) sih
                on 
                    (
                        ve.company_id = sih.company_id
                    and ve.[Document No_] = sih.[No_]
                    )
            ) d
        join
            ext.Item_Ledger_Entry e
        on
            (
                d.company_id = e.company_id
            and d.ile_entry_no = e. ile_entry_no
            )
        group by
            d.company_id,
            isnull(e.country_id,-1),
            d.key_posting_date,
            d.opt_key + case when d.ve_entry_no = e.value_entry_original then 1 else 2 end,
            d.is_amazon,
            d.key_DocumentType,
            d.key_location,
            d.key_sku,
            d.key_batch

    end

if @partition = 6

    begin

        if month(getutcdate()) > 6 set @datefrom = datefromparts(year(getutcdate()),1,1) else set @datefrom = datefromparts(year(getutcdate())-1,1,1)

        delete from stock.StockManagement_Archive where key_posting_date >= @datefrom and key_posting_date <= eomonth(dateadd(month,-6,getutcdate()))

        insert into stock.StockManagement_Archive (company_id, country_id, key_posting_date, opt_key, is_amazon, key_DocumentType, key_location, key_batch, Quantity, [Cost Actual], [Cost Expected], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount])
        select
            d.company_id,
            isnull(e.country_id,-1),
            eomonth(max(d.key_posting_date)) key_posting_date,
            d.opt_key + case when d.ve_entry_no = e.value_entry_original then 1 else 2 end opt_key,
            d.is_amazon,
            d.key_DocumentType,
            isnull(d.key_location,(select top 1 ID from ext.Location l where d.company_id = l.company_id and l.default_loc = 1)) key_location,
            d.key_batch,
            isnull(sum(case when d.ve_entry_no = e.value_entry_original then d.Quantity else 0 end),0) Quantity,
            isnull(sum(d.[Cost Actual]),0) [Cost Actual],
            isnull(sum(d.[Cost Expected]),0) [Cost Expected],
            isnull(sum(d.[Cost Posted to G_L]),0) [Cost Posted to G_L],
            isnull(sum(d.[Sales Amount (Actual)]),0) [Sales Amount (Actual)],
            isnull(sum([Discount Amount]),0) [Discount Amount]
        from
            (
                select
                    ile.company_id,
                    ile.[Entry No_] ile_entry_no,
                    ve.[Entry No_] ve_entry_no,
                    ve.[Posting Date] key_posting_date,
                    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end opt_key,
                    case when amz.warehouse is null then 0 else 1 end is_amazon,
                    case when sih.[Sell-to Customer No_] in  (select cus_code from finance.SalesInvoices_Amazon) or amz.warehouse is not null then 1001 else ve.[Document Type] end key_DocumentType,
                    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
                    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
                    ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
                    ile.Quantity,
                    ve.[Cost Actual],
                    ve.[Cost Expected],
                    ve.[Cost Posted to G_L],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 and amz.warehouse is not null then db_sys.fn_divide(ve.[Sales Amount (Actual)],vat.vat_rate,default) else ve.[Sales Amount (Actual)] end [Sales Amount (Actual)],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
                from
                    (select 1 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[UK$Item Ledger Entry]) ile
                join 
                    (
                        select
                            ve.company_id,
                            [Item Ledger Entry No_] ileNo,
                            [Entry No_],
                            [Posting Date],
                            [Document Type],
                            [Document No_],
                            [Document Line No_],
                            [Adjustment],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                        from
                            (select 1 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[UK$Value Entry]) ve
                        where
                            (
                                ve.[Posting Date] >= @datefrom
                            and ve.[Posting Date] <= eomonth(dateadd(month,-6,getutcdate()))
                            )
                    ) ve
                on
                    (
                        ile.company_id = ve.company_id
                    and ile.[Entry No_] = ve.ileNo
                    )
                left join
                    finance.SalesInvoices_Amazon amz
                on
                    (
                        ile.company_id = 1
                    and ile.[Location Code] = amz.warehouse
                    )
                left join
                    [dbo].[UK$Customer] amz_c
                on
                    (
                        amz.cus_code = amz_c.No_
                    )
                left join
                    (select 1 company_id, [Document No_], [Line No_], [Promotion Discount Amount] from [dbo].[UK$Sales Invoice Line]) sil
                on
                    (
                        ve.company_id = sil.company_id
                    and ve.[Document No_] = sil.[Document No_] 
                    and ve.[Document Line No_] = sil.[Line No_]
                    and ve.[Adjustment] = 0
                    )
                left join
                    (select 1 company_id, [No_], [Sell-to Customer No_], [Currency Factor] from [dbo].[UK$Sales Invoice Header]) sih
                on 
                    (
                        ve.company_id = sih.company_id
                    and ve.[Document No_] = sih.[No_]
                    )
                left join
                    (
                    select
                        1 company_id,
                        i.[No_],
                        v.[VAT Bus_ Posting Group],
                        (v.[VAT _]/100)+1 vat_rate
                    from
                        [dbo].[UK$Item] i 
                    join
                        [dbo].[UK$VAT Posting Setup] v
                    on
                        (
                            i.[VAT Prod_ Posting Group] = v.[VAT Prod_ Posting Group]
                        )
                    ) vat 
                on
                    (
                        ile.company_id = vat.company_id
                    and ile.[Item No_] = vat.[No_]
                    and amz_c.[VAT Bus_ Posting Group] = vat.[VAT Bus_ Posting Group]
                    )

                union all

                select
                    ile.company_id,
                    ile.[Entry No_] ile_entry_no,
                    ve.[Entry No_] ve_entry_no,
                    ve.[Posting Date] key_posting_date,
                    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end opt_key,
                    0 is_amazon,
                    ve.[Document Type] key_DocumentType,
                    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
                    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
                    ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
                    ile.Quantity,
                    ve.[Cost Actual],
                    ve.[Cost Expected],
                    ve.[Cost Posted to G_L],
                    ve.[Sales Amount (Actual)],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
                from
                    (select 4 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[NL$Item Ledger Entry]) ile
                join 
                    (
                        select
                            ve.company_id,
                            [Item Ledger Entry No_] ileNo,
                            [Entry No_],
                            [Posting Date],
                            [Document Type],
                            [Document No_],
                            [Document Line No_],
                            [Adjustment],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                        from
                            (select 4 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[NL$Value Entry]) ve
                        where
                            (
                                ve.[Posting Date] >= @datefrom
                            and ve.[Posting Date] <= eomonth(dateadd(month,-6,getutcdate()))
                            )
                    ) ve
                on
                    (
                        ile.company_id = ve.company_id
                    and ile.[Entry No_] = ve.ileNo
                    )
                left join
                    (select 4 company_id, [Document No_], [Line No_], [Promotion Discount Amount] from [dbo].[NL$Sales Invoice Line]) sil
                on
                    (
                        ve.company_id = sil.company_id
                    and ve.[Document No_] = sil.[Document No_] 
                    and ve.[Document Line No_] = sil.[Line No_]
                    and ve.[Adjustment] = 0
                    )
                left join
                    (select 4 company_id, [No_], [Sell-to Customer No_], [Currency Factor] from [dbo].[NL$Sales Invoice Header]) sih
                on 
                    (
                        ve.company_id = sih.company_id
                    and ve.[Document No_] = sih.[No_]
                    )


                union all

                select
                    ile.company_id,
                    ile.[Entry No_] ile_entry_no,
                    ve.[Entry No_] ve_entry_no,
                    ve.[Posting Date] key_posting_date,
                    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end opt_key,
                    0 is_amazon,
                    ve.[Document Type] key_DocumentType,
                    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
                    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
                    ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
                    ile.Quantity,
                    ve.[Cost Actual],
                    ve.[Cost Expected],
                    ve.[Cost Posted to G_L],
                    ve.[Sales Amount (Actual)],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
                from
                    (select 5 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[NZ$Item Ledger Entry]) ile
                join 
                    (
                        select
                            ve.company_id,
                            [Item Ledger Entry No_] ileNo,
                            [Entry No_],
                            [Posting Date],
                            [Document Type],
                            [Document No_],
                            [Document Line No_],
                            [Adjustment],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                        from
                            (select 5 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[NZ$Value Entry]) ve
                        where
                            (
                                ve.[Posting Date] >= @datefrom
                            and ve.[Posting Date] <= eomonth(dateadd(month,-6,getutcdate()))
                            )
                    ) ve
                on
                    (
                        ile.company_id = ve.company_id
                    and ile.[Entry No_] = ve.ileNo
                    )
                left join
                    (select 5 company_id, [Document No_], [Line No_], [Promotion Discount Amount] from [dbo].[NZ$Sales Invoice Line]) sil
                on
                    (
                        ve.company_id = sil.company_id
                    and ve.[Document No_] = sil.[Document No_] 
                    and ve.[Document Line No_] = sil.[Line No_]
                    and ve.[Adjustment] = 0
                    )
                left join
                    (select 5 company_id, [No_], [Sell-to Customer No_], [Currency Factor] from [dbo].[NZ$Sales Invoice Header]) sih
                on 
                    (
                        ve.company_id = sih.company_id
                    and ve.[Document No_] = sih.[No_]
                    )

                union all

                select
                    ile.company_id,
                    ile.[Entry No_] ile_entry_no,
                    ve.[Entry No_] ve_entry_no,
                    ve.[Posting Date] key_posting_date,
                    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end opt_key,
                    0 is_amazon,
                    ve.[Document Type] key_DocumentType,
                    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
                    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
                    ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
                    ile.Quantity,
                    ve.[Cost Actual],
                    ve.[Cost Expected],
                    ve.[Cost Posted to G_L],
                    ve.[Sales Amount (Actual)],
                    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
                from
                    (select 6 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[IE$Item Ledger Entry]) ile
                join 
                    (
                        select
                            ve.company_id,
                            [Item Ledger Entry No_] ileNo,
                            [Entry No_],
                            [Posting Date],
                            [Document Type],
                            [Document No_],
                            [Document Line No_],
                            [Adjustment],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                            ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                        from
                            (select 6 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[IE$Value Entry]) ve
                        where
                            (
                                ve.[Posting Date] >= @datefrom
                            and ve.[Posting Date] <= eomonth(dateadd(month,-6,getutcdate()))
                            )
                    ) ve
                on
                    (
                        ile.company_id = ve.company_id
                    and ile.[Entry No_] = ve.ileNo
                    )
                left join
                    (select 6 company_id, [Document No_], [Line No_], [Promotion Discount Amount] from [dbo].[IE$Sales Invoice Line]) sil
                on
                    (
                        ve.company_id = sil.company_id
                    and ve.[Document No_] = sil.[Document No_] 
                    and ve.[Document Line No_] = sil.[Line No_]
                    and ve.[Adjustment] = 0
                    )
                left join
                    (select 6 company_id, [No_], [Sell-to Customer No_], [Currency Factor] from [dbo].[IE$Sales Invoice Header]) sih
                on 
                    (
                        ve.company_id = sih.company_id
                    and ve.[Document No_] = sih.[No_]
                    )
            ) d
        join
            ext.Item_Ledger_Entry e
        on
            (
                d.company_id = e.company_id
            and d.ile_entry_no = e. ile_entry_no
            )
        group by
            d.company_id,
            isnull(e.country_id,-1),
            year(d.key_posting_date),
            d.opt_key + case when d.ve_entry_no = e.value_entry_original then 1 else 2 end,
            d.is_amazon,
            d.key_DocumentType,
            d.key_location,
            d.key_sku,
            d.key_batch

    end

GO
