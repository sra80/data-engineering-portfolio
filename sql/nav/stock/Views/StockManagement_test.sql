
create view [stock].[StockManagement_test]

as

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
	(select 1 company_id, [Entry No_], [Posting Date], [Location Code], [Item No_], [Variant Code], [Lot No_], [Quantity] from [dbo].[UK$Item Ledger Entry]) ile
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
			ext.fn_Convert_Currency_GBP([Cost Amount (Actual)],ve.company_id,ve.[Posting Date]) [Cost Actual],
			ext.fn_Convert_Currency_GBP([Cost Amount (Expected)],ve.company_id,ve.[Posting Date]) [Cost Expected],
            ext.fn_Convert_Currency_GBP([Cost Posted to G_L],ve.company_id,ve.[Posting Date]) [Cost Posted to G_L], 
            ext.fn_Convert_Currency_GBP([Sales Amount (Actual)],ve.company_id,ve.[Posting Date]) [Sales Amount (Actual)],
            ext.fn_Convert_Currency_GBP([Discount Amount],ve.company_id,ve.[Posting Date]) [Discount Amount]
		from
			(select 1 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[UK$Value Entry]) ve
        left join
            (select 1 company_id, [Item Ledger Entry No_] ile, min([Entry No_]) [Entry No_] from [dbo].[UK$Value Entry] group by [Item Ledger Entry No_]) original_entry
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
    case when datediff(month,ve.[Posting Date],getdate()) <= 5 then datediff(month,ve.[Posting Date],getdate()) else datediff(year,ve.[Posting Date],getdate()) + 6 end model_partition,
	ile.company_id,
    convert(date,ve.[Posting Date]) key_posting_date,
    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end + case ve.is_original_entry when 1 then 1 else 2 end opt_key,
    0 is_amazon,
    ve.[Document Type] key_DocumentType,
    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
	ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
	case when ve.is_original_entry = 1 then ile.Quantity else 0 end Quantity,
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
			(select 4 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[NL$Value Entry]) ve
        left join
            (select 4 company_id, [Item Ledger Entry No_] ile, min([Entry No_]) [Entry No_] from [dbo].[NL$Value Entry] group by [Item Ledger Entry No_]) original_entry
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
    case when datediff(month,ve.[Posting Date],getdate()) <= 5 then datediff(month,ve.[Posting Date],getdate()) else datediff(year,ve.[Posting Date],getdate()) + 6 end model_partition,
	ile.company_id,
    convert(date,ve.[Posting Date]) key_posting_date,
    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end + case ve.is_original_entry when 1 then 1 else 2 end opt_key,
    0 is_amazon,
    ve.[Document Type] key_DocumentType,
    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
	ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
	case when ve.is_original_entry = 1 then ile.Quantity else 0 end Quantity,
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
			(select 5 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[NZ$Value Entry]) ve
        left join
            (select 5 company_id, [Item Ledger Entry No_] ile, min([Entry No_]) [Entry No_] from [dbo].[NZ$Value Entry] group by [Item Ledger Entry No_]) original_entry
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
    case when datediff(month,ve.[Posting Date],getdate()) <= 5 then datediff(month,ve.[Posting Date],getdate()) else datediff(year,ve.[Posting Date],getdate()) + 6 end model_partition,
	ile.company_id,
    convert(date,ve.[Posting Date]) key_posting_date,
    case ve.Adjustment when 1 then 100 else 200 end + case when eomonth(ile.[Posting Date]) = eomonth(ve.[Posting Date]) then 10 else 20 end + case ve.is_original_entry when 1 then 1 else 2 end opt_key,
    0 is_amazon,
    ve.[Document Type] key_DocumentType,
    (select ID from ext.Location loc where loc.company_id = ile.company_id and loc.location_code = ile.[Location Code]) key_location,
    (select ID from ext.Item i where i.company_id = ile.company_id and i.No_ = ile.[Item No_]) key_sku,
	ext.fn_Item_Batch_Info(ile.company_id,ile.[Item No_],ile.[Variant Code],ile.[Lot No_]) key_batch,
	case when ve.is_original_entry = 1 then ile.Quantity else 0 end Quantity,
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
			(select 6 company_id, [Entry No_], [Item Ledger Entry No_], [Posting Date], [Document Type], [Document No_], [Document Line No_], [Adjustment], [Cost Amount (Actual)], [Cost Amount (Expected)], [Cost Posted to G_L], [Sales Amount (Actual)], [Discount Amount] from [dbo].[IE$Value Entry]) ve
        left join
            (select 6 company_id, [Item Ledger Entry No_] ile, min([Entry No_]) [Entry No_] from [dbo].[IE$Value Entry] group by [Item Ledger Entry No_]) original_entry
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
GO
