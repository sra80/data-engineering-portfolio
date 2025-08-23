
CREATE view [stock].[StockManagement_old]

as

select
    model_partition,
    company_id,
    key_posting_date,
    opt_key,
    is_amazon,
    key_DocumentType,
    key_location,
    key_sku,
    key_batch,
    sum(Quantity) Quantity,
    sum([Cost Actual]) [Cost Actual],
    sum([Cost Expected]) [Cost Expected],
    sum([Cost Posted to G_L]) [Cost Posted to G_L],
    sum([Sales Amount (Actual)]) [Sales Amount (Actual)],
    sum([Discount Amount]) [Discount Amount]
from
    (
        select
            case when datediff(month,ve.[Posting Date],getdate()) <= 5 then datediff(month,ve.[Posting Date],getdate()) else datediff(year,ve.[Posting Date],getdate()) + 6 end model_partition,
            ile.company_id,
            convert(date,ve.[Posting Date]) key_posting_date,
            case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end + case ve.is_original_entry when 1 then 1 else 2 end opt_key,
            case when amz.warehouse is null then 0 else 1 end is_amazon,
            case when sih.[Sell-to Customer No_] in  (select cus_code from finance.SalesInvoices_Amazon) or amz.warehouse is not null then 1001 else ve.[Document Type] end key_DocumentType,
            (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
            (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
            ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
            case when ve.is_original_entry = 1 then ile.Quantity else 0 end Quantity,
            ve.[Cost Actual],
            ve.[Cost Expected],
            ve.[Cost Posted to G_L],
            case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 and amz.warehouse is not null then db_sys.fn_divide(ve.[Sales Amount (Actual)],vat.vat_rate,default) else ve.[Sales Amount (Actual)] end [Sales Amount (Actual)],
            case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(sil.[Promotion Discount Amount],isnull(nullif(sih.[Currency Factor],0),1),default) end [Discount Amount]
        from
            [hs_consolidated].[Item Ledger Entry] ile
        join 
            (
                select
                    ve.company_id,
                    [Item Ledger Entry No_] ileNo,
                    [Posting Date],
                    [Document Type],
                    [Document No_],
                    [Document Line No_],
                    [Adjustment],
                    case when original_entry.ile is null then 0 else 1 end [is_original_entry],
                    -- [Dimension Set ID],
                    ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
                    ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
                    ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
                    ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
                    ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
                from
                    [hs_consolidated].[Value Entry] ve
                left join
                    (select company_id, [Item Ledger Entry No_] ile, min([Entry No_]) [Entry No_] from [hs_consolidated].[Value Entry] group by company_id, [Item Ledger Entry No_]) original_entry
                on
                    (
                        ve.company_id = original_entry.company_id
                    and ve.[Item Ledger Entry No_] = original_entry.ile
                    and ve.[Entry No_] = original_entry.[Entry No_]
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
            [hs_consolidated].[Sales Invoice Line] sil
        on
            (
                ve.company_id = sil.company_id
            and ve.[Document No_] = sil.[Document No_] 
            and ve.[Document Line No_] = sil.[Line No_]
            and ve.[Adjustment] = 0
            )
        left join
            [hs_consolidated].[Sales Invoice Header] sih
        on 
            (
                ve.company_id = sih.company_id
            and ve.[Document No_] = sih.[No_]
            )
        left join
            (
            select
                i.company_id,
                i.[No_],
                v.[VAT Bus_ Posting Group],
                (v.[VAT _]/100)+1 vat_rate
            from
                [hs_consolidated].[Item] i 
            join
                [hs_consolidated].[VAT Posting Setup] v
            on
                (
                    i.company_id = v.company_id
                and i.[VAT Prod_ Posting Group] = v.[VAT Prod_ Posting Group]
                )
            ) vat 
        on
            (
                ile.company_id = vat.company_id
            and ile.[Item No_] = vat.[No_]
            and amz_c.[VAT Bus_ Posting Group] = vat.[VAT Bus_ Posting Group]
            )
    ) x
group by
    model_partition,
    company_id,
    key_posting_date,
    opt_key,
    is_amazon,
    key_DocumentType,
    key_location,
    key_sku,
    key_batch
GO
