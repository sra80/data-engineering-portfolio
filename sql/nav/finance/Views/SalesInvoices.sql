create or alter view [finance].[SalesInvoices]
 
as
 
--UK
select
    ve._partition [model_partition],
        (1*power(10,7))+
        (options.key_DocumentType*power(10,6))+
        (options.is_discountSale)*power(10,5)+
        (    case when is_discountSale = 1 then
                case 
                    when bridge.[Sell-to Customer No_] in (select cus from finance.nominal_codes) then 1
                    when left(mc.Audience,5) = 'STAFF' then 2
                    else 3
                end
            else 0 end
        )*(power(10,4))+
        (options.is_honesty*power(10,3))+
        (options.[is_amazonFBA]*(power(10,2)))+
        (options.is_amazonShipment*10)+
        ve.[Adjustment] key_option,
 	datediff(month,bridge.dgdOrderDate,ve.[Posting Date]) key_InvoiceLeadTime_Month,
    datediff(year,bridge.dgdOrderDate,ve.[Posting Date]) key_InvoiceLeadTime_Year,
 	(select ID from ext.Location where Location.company_id = 1 and ve.[Location Code] = Location.location_code) [keyLocation],
    hs_identity.fn_Customer(1,bridge.[Sell-to Customer No_]) keyCustomer,
    (select ID from ext.Item where Item.company_id = 1 and Item.No_ = ve.[Item No_]) [keySKU],
 	convert(date,ve.[Posting Date]) [keyInvoiceDate],
    ext.fn_Channel(1,isnull(nullif(bridge.[Channel Code],''),'PHONE')) keyChannel,
    (select ID from ext.Campaign where Campaign.company_id = 1 and Campaign.campaign_code = bridge.[Campaign No_]) keyCampaign,
    ext.fn_Media_Code(1,nullif(bridge.[Media Code],'')) keyMedia,
    isnull((select ID from ext.Country_Region where Country_Region.company_id = 1 and Country_Region.country_code = bridge.[Ship-to Country_Region Code]),-1) [keyCountryCode],
    case when (select [Customer Type] from [UK$Customer] c where c.No_ = bridge.[Sell-to Customer No_]) = 'B2B_PARTNR' then bridge.[Ship-to Name] end [Customer Name],
    bridge.dgdOrderDate,
    (1*10000)+ve.[Dimension Set ID] [keyDimensionSetID],
    ext.fn_VAT_Posting_Setup(1,bridge.[VAT Bus_ Posting Group],bridge.[VAT Prod_ Posting Group]) keyVATPostingSetup,
 	ext.fn_Currency(bridge.[Currency Code]) [keyCurrency],
    (select ID from ext.Return_Reason rr where rr.company_id = 1 and rr.code = scl.[Return Reason Code]) [keyReturnReasonCode],
    -ve.[Invoiced Quantity] [Quantity],
 	-ve.[Cost Posted to G_L] [CostPosted],
    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(bridge.[Line Discount Amount],bridge.[Currency Factor],default) end [Total Discount Amount (LCY)],
    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] else db_sys.fn_divide(bridge.[Promotion Discount Amount],bridge.[Currency Factor],default) end [Promotion Discount Amount (LCY)],
    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then 0 else db_sys.fn_divide(bridge.[System Discount Amount],bridge.[Currency Factor],default) end [System Discount Amount (LCY)],
    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then 0 else db_sys.fn_divide(bridge.[Manual Discount Amount],bridge.[Currency Factor],default) end [Manual Discount Amount (LCY)],
    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Sales Amount (Actual)] else db_sys.fn_divide(bridge.[Amount Including VAT],bridge.[Currency Factor],default) end [Gross Sales Amount (LCY)],
    case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then db_sys.fn_divide(ve.[Sales Amount (Actual)],vat.[VAT Rate],ve.[Sales Amount (Actual)]) else db_sys.fn_divide(bridge.Amount,bridge.[Currency Factor],default) end [Net Sales Amount (LCY)],
    isnull(-ve.[Invoiced Quantity]*ext.fn_sales_price(bridge.[No_],bridge.[Posting Date],'FULLPRICES'),0) [_RRP],
 	case when bridge.[Currency Code] = gls.[LCY Code] then 0 else 
        case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Sales Amount (Actual)] * 
            case when ve.[Location Code] = amz.warehouse then [ext].[fn_currency_exchange_rates](ve.[Posting Date],amz.currency_code) else 1 end
        else bridge.[Amount Including VAT] end 
    end [Gross Sales Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else
        case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then db_sys.fn_divide(ve.[Sales Amount (Actual)],vat.[VAT Rate],ve.[Sales Amount (Actual)]) *
            case when ve.[Location Code] = amz.warehouse then [ext].[fn_currency_exchange_rates](ve.[Posting Date],amz.currency_code) else 1 end
        else bridge.[Amount] end
    end [Net Sales Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else 
        case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] *
            case when ve.[Location Code] = amz.warehouse then [ext].[fn_currency_exchange_rates](ve.[Posting Date],amz.currency_code) else 1 end
        else bridge.[Line Discount Amount] end
    end [Total Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else
        case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then ve.[Discount Amount] *
            case when ve.[Location Code] = amz.warehouse then [ext].[fn_currency_exchange_rates](ve.[Posting Date],amz.currency_code) else 1 end
        else bridge.[Promotion Discount Amount] end 
    end [Promotion Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Manual Discount Amount] end [Manual Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[System Discount Amount] end [System Discount Amount (FCY)]
 from
     (
         select
            p._partition,
            [Document No_],
            [Document Line No_],
            [Posting Date],
            [Adjustment],
            [Item Ledger Entry Type],
            [Document Type],
            [Location Code],
            [Item No_],
            [Item Ledger Entry No_],
            [Dimension Set ID],
            [Document Date],
            [Entry No_],
            [Invoiced Quantity],
            [Cost Posted to G_L],
            [Discount Amount],
            [Sales Amount (Actual)]
         from
            [dbo].[UK$Value Entry] ve
        join
            db_sys.model_partition_month p
        on
            (
                year(ve.[Posting Date]) = p._year
            and month(ve.[Posting Date]) = p._month
            )
         where
            (
                [Item Ledger Entry Type] = 1 
            and [Document Type] in (0,2,4)
            and ve.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
            )
      ) ve
cross apply
    [dbo].[UK$General Ledger Setup] gls
  left join
     (
         select
            v.[Document No_],
 			v.[Document Line No_],
 			v.[Posting Date],
 			v.[Adjustment],
            v.[Item Ledger Entry Type],
            v.[Document Type],
            min(v.[Entry No_]) [Entry No_]
         from
            [dbo].[UK$Value Entry] v
         where
            (
                v.[Item Ledger Entry Type] = 1
            and v.[Document Type] in (2,4)
            )
         group by
            v.[Document No_],
 			v.[Document Line No_],
 			v.[Posting Date],
 			v.[Adjustment],
            v.[Item Ledger Entry Type],
            v.[Document Type]
     ) ve_fl --value entry first line
 on
    (
        ve.[Document No_] = ve_fl.[Document No_]
 	and ve.[Document Line No_] = ve_fl.[Document Line No_]
 	and ve.[Posting Date] = ve_fl.[Posting Date]
 	and ve.[Adjustment] = ve_fl.[Adjustment]
    and ve.[Item Ledger Entry Type] = ve_fl.[Item Ledger Entry Type]
    and ve.[Document Type] = ve_fl.[Document Type]
    )
left join
    [dbo].[UK$Sales Invoice Line] sil
on
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sil.[Document No_] 
    and ve.[Document Line No_] = sil.[Line No_]
    and ve.[Adjustment] = 0
    )
left join
    [dbo].[UK$Sales Invoice Header] sih
on 
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sih.[No_]
    )
left join
    [dbo].[UK$Sales Invoice Line] sil_adj
on
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sil_adj.[Document No_] 
    and ve.[Document Line No_] = sil_adj.[Line No_]
    and ve.[Adjustment] = 1
    )
left join
    [dbo].[UK$Sales Cr_Memo Line] scl
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = scl.[Document No_] 
    and ve.[Document Line No_] = scl.[Line No_]
    and ve.[Adjustment] = 0
    )
left join
    [dbo].[UK$Sales Cr_Memo Header] sch
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = sch.[No_]
    )
left join
    [dbo].[UK$Sales Cr_Memo Line] scl_adj
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = scl_adj.[Document No_] 
    and ve.[Document Line No_] = scl_adj.[Line No_]
    and ve.[Adjustment] = 1
    )
 left join
    finance.SalesInvoices_Amazon amz
 on
    (
        ve.[Document Type] = 0
    and ve.[Location Code] = amz.warehouse
    )
 left join
    [dbo].[UK$Item Ledger Entry] ile
 on
    (
        ve.[Document Type] = 0
    and ile.[Entry No_] = ve.[Item Ledger Entry No_]
    )
 left join
 	(
        select
            i.[No_],
            d.[Ship-to Country_Region Code],
            v.[VAT Bus_ Posting Group],
            v.[VAT Prod_ Posting Group],
            (v.[VAT _]/100)+1 [VAT Rate]
        from
            [dbo].[UK$Item] i 
        join
            [dbo].[UK$VAT Posting Setup] v
        on
            (
                i.[VAT Prod_ Posting Group] = v.[VAT Prod_ Posting Group]
            )
        join
            [dbo].[UK$Distance Sale VAT] d 
        on
            (
                v.[VAT Bus_ Posting Group] = d.[VAT Bus_ Posting Group]
            )
        where
            (
                d.[Location Code] = 'WASDSP'
            and d.[VAT Bus_ Posting Group] <> 'STD'
            )
 	) vat 
 on
    (
        ve.[Document Type] = 0
    and ve.[Item No_] = vat.[No_]
    and ile.[Country_Region Code] = vat.[Ship-to Country_Region Code]
    )
 cross apply
     (
        select 
            case ve.[Document Type] 
                when 0 then 
                    case when ve.[Location Code] = amz.warehouse then 
                        amz.cus_code 
                    end 
                when 2 then sih.[Sell-to Customer No_] 
                when 4 then sch.[Sell-to Customer No_] 
            end [Sell-to Customer No_],
            case ve.[Document Type] when 2 then sih.[Ship-to Name] when 4 then sch.[Ship-to Name] end [Ship-to Name],
            case ve.[Document Type] when 0 then case when ve.[Location Code] = amz.warehouse then amz.channel_code end when 2 then sih.[Channel Code] when 4 then sch.[Channel Code] end [Channel Code],
            case ve.[Document Type] when 2 then sih.[Campaign No_] when 4 then sch.[Campaign No_] end [Campaign No_],
            case ve.[Document Type] when 0 then case when ve.[Location Code] = amz.warehouse then amz.media_code end when 2 then sih.[Media Code] when 4 then sch.[Media Code] end [Media Code],
            convert(date,case ve.[Document Type] when 0 then ve.[Document Date] when 2 then sih.[Order Date] end) dgdOrderDate,
            isnull(nullif(case ve.[Document Type] when 2 then sih.[Currency Factor] when 4 then sch.[Currency Factor] end,0),1) [Currency Factor],
            isnull(
                    nullif(
                        case ve.[Document Type] 
                            when 0 then
                                case when ve.[Location Code] = amz.warehouse then 
                                    amz.currency_code
                                end 
                                when 2 then sih.[Currency Code] 
                                when 4 then sch.[Currency Code] 
                            end
                            ,''
                        ),(select [LCY Code] from [dbo].[UK$General Ledger Setup] gls)
                     ) 
                    [Currency Code],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Amount Including VAT] when 4 then -scl.[Amount Including VAT] end else 0 end,0) [Amount Including VAT], 
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Amount] when 4 then -scl.[Amount] end else 0 end,0) [Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Line Discount Amount] when 4 then -scl.[Line Discount Amount] end else 0 end,0) [Line Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Promotion Discount Amount] when 4 then -scl.[Promotion Discount Amount] end else 0 end,0) [Promotion Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Manual Discount Amount] when 4 then -scl.[Manual Discount Amount] end else 0 end,0) [Manual Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[System Discount Amount] when 4 then -scl.[System Discount Amount] end else -0 end,0) [System Discount Amount],
            case ve.[Document Type] 
                when 0 then ve.[Item No_]
                when 2 then sil.[No_] 
                when 4 then scl.[No_] 
            end No_,
            case ve.[Document Type] 
                when 0 then ve.[Posting Date]
                when 2 then sil.[Posting Date] 
                when 4 then scl.[Posting Date] 
            end [Posting Date],
            case ve.[Document Type] 
                when 0 then ile.[Country_Region Code]
                when 2 then sih.[Ship-to Country_Region Code] 
                when 4 then sch.[Ship-to Country_Region Code] 
            end [Ship-to Country_Region Code],
             case ve.[Document Type] 
                when 0 then 
                    vat.[VAT Bus_ Posting Group]
                when 2 then 
                    case ve.[Adjustment] when 0 then sil.[VAT Bus_ Posting Group] when 1 then sil_adj.[VAT Bus_ Posting Group] end
                when 4 then 
                    case ve.[Adjustment] when 0 then scl.[VAT Bus_ Posting Group] when 1 then scl_adj.[VAT Bus_ Posting Group] end 
             end [VAT Bus_ Posting Group],
             case ve.[Document Type] 
                when 0 then
                    vat.[VAT Prod_ Posting Group]
                when 2 then 
                    case ve.[Adjustment] when 0 then sil.[VAT Prod_ Posting Group] when 1 then sil_adj.[VAT Prod_ Posting Group] end
                when 4 then 
                    case ve.[Adjustment] when 0 then scl.[VAT Prod_ Posting Group] when 1 then scl_adj.[VAT Prod_ Posting Group] end 
             end [VAT Prod_ Posting Group]
     ) bridge
cross apply
    (
        select
            case when bridge.[Sell-to Customer No_] in  (select cus_code from finance.SalesInvoices_Amazon) or amz.warehouse is not null then 1 else 0 end [is_amazonFBA],
            case when amz.warehouse is not null then 1 else 0 end [is_amazonShipment],
            case when ve.[Document Type] = 2 then 1 when ve.[Document Type] = 4 then 2 when bridge.[Sell-to Customer No_] in  (select cus_code from finance.SalesInvoices_Amazon) or amz.warehouse is not null then 3 else 999 end key_DocumentType,
            case when sih.[Order No_] is null then 0 else case when len(sih.[Order No_]) = 0 then 1 else 0 end end [is_honesty],
            case when -ve.[Cost Posted to G_L] > case when ve.[Document Type] = 0 and ve.[Adjustment] = 0 then db_sys.fn_divide(ve.[Sales Amount (Actual)],vat.[VAT Rate],ve.[Sales Amount (Actual)]) else db_sys.fn_divide(bridge.Amount,bridge.[Currency Factor],default) end then 1 else 0 end is_discountSale
    ) options
left join
    [dbo].[UK$Media Code] mc
on
    (
        bridge.[Media Code] = mc.Code
    )
 where
    (
        ve.[Document Type] in (2,4)
    or
        (
            ve.[Document Type] = 0
        and ve.[Location Code] = amz.warehouse
        )
    )
 
union all

--NL
select
    ve._partition [model_partition],
        (4*power(10,7))+
        (options.key_DocumentType*power(10,6))+
        (options.is_discountSale)*power(10,5)+
        (    case when is_discountSale = 1 then
                case
                    when left(mc.Audience,5) = 'STAFF' then 2
                    else 3
                end
            else 0 end
        )*(power(10,4))+
        (options.is_honesty*power(10,3))+
        (options.[is_amazonFBA]*(power(10,2)))+
        (options.is_amazonShipment*10)+
        ve.[Adjustment] key_option,
 	datediff(month,bridge.dgdOrderDate,ve.[Posting Date]) key_InvoiceLeadTime_Month,
    datediff(year,bridge.dgdOrderDate,ve.[Posting Date]) key_InvoiceLeadTime_Year,
 	(select ID from ext.Location where Location.company_id = 1 and ve.[Location Code] = Location.location_code) [keyLocation],
    hs_identity.fn_Customer(4,bridge.[Sell-to Customer No_]) keyCustomer,
    (select ID from ext.Item where Item.company_id = 1 and Item.No_ = ve.[Item No_]) [keySKU],
 	convert(date,ve.[Posting Date]) [keyInvoiceDate],
    ext.fn_Channel(1,isnull(nullif(bridge.[Channel Code],''),'PHONE')) keyChannel,
    (select ID from ext.Campaign where Campaign.company_id = 1 and Campaign.campaign_code = bridge.[Campaign No_]) keyCampaign,
    ext.fn_Media_Code(1,nullif(bridge.[Media Code],'')) keyMedia,
    isnull((select ID from ext.Country_Region where Country_Region.company_id = 1 and Country_Region.country_code = bridge.[Ship-to Country_Region Code]),-1) [keyCountryCode],
    case when (select [Customer Type] from [NL$Customer] c where c.No_ = bridge.[Sell-to Customer No_]) = 'B2B_PARTNR' then bridge.[Ship-to Name] end [Customer Name],
    bridge.dgdOrderDate,
    (4*10000)+ve.[Dimension Set ID] [keyDimensionSetID],
    ext.fn_VAT_Posting_Setup(1,bridge.[VAT Bus_ Posting Group],bridge.[VAT Prod_ Posting Group]) keyVATPostingSetup,
 	ext.fn_Currency(bridge.[Currency Code]) [keyCurrency],
    (select ID from ext.Return_Reason rr where rr.company_id = 1 and rr.code = scl.[Return Reason Code]) [keyReturnReasonCode],
    -ve.[Invoiced Quantity] [Quantity],
 	-ext.fn_Convert_Currency_GBP(ve.[Cost Posted to G_L],4,ve.[Posting Date]) [CostPosted],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Line Discount Amount],bridge.[Currency Factor],default),4,ve.[Posting Date]) [Total Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Promotion Discount Amount],bridge.[Currency Factor],default),4,ve.[Posting Date]) [Promotion Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[System Discount Amount],bridge.[Currency Factor],default),4,ve.[Posting Date]) [System Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Manual Discount Amount],bridge.[Currency Factor],default),4,ve.[Posting Date]) [Manual Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Amount Including VAT],bridge.[Currency Factor],default),4,ve.[Posting Date]) [Gross Sales Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.Amount,bridge.[Currency Factor],default),4,ve.[Posting Date]) [Net Sales Amount (LCY)],
    isnull(-ve.[Invoiced Quantity]*ext.fn_sales_price_GBP(4,bridge.[No_],bridge.[Posting Date],'FULLPRICES'),0) [_RRP],
 	case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Amount Including VAT] end [Gross Sales Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Amount] end [Net Sales Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Line Discount Amount] end [Total Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Promotion Discount Amount] end [Promotion Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Manual Discount Amount] end [Manual Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[System Discount Amount] end [System Discount Amount (FCY)]
 from
     (
         select
            p._partition,
            [Document No_],
            [Document Line No_],
            [Posting Date],
            [Adjustment],
            [Item Ledger Entry Type],
            [Document Type],
            [Location Code],
            [Item No_],
            [Item Ledger Entry No_],
            [Dimension Set ID],
            [Document Date],
            [Entry No_],
            [Invoiced Quantity],
            [Cost Posted to G_L],
            [Discount Amount],
            [Sales Amount (Actual)]
         from
            [dbo].[NL$Value Entry] ve
        join
            db_sys.model_partition_month p
        on
            (
                year(ve.[Posting Date]) = p._year
            and month(ve.[Posting Date]) = p._month
            )
         where
            (
                [Item Ledger Entry Type] = 1 
            and [Document Type] in (2,4)
            and ve.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
            )
      ) ve
cross apply
    [dbo].[NL$General Ledger Setup] gls
  left join
     (
         select
            v.[Document No_],
 			v.[Document Line No_],
 			v.[Posting Date],
 			v.[Adjustment],
            v.[Item Ledger Entry Type],
            v.[Document Type],
            min(v.[Entry No_]) [Entry No_]
         from
            [dbo].[NL$Value Entry] v
         where
            (
                v.[Item Ledger Entry Type] = 1
            and v.[Document Type] in (2,4)
            )
         group by
            v.[Document No_],
 			v.[Document Line No_],
 			v.[Posting Date],
 			v.[Adjustment],
            v.[Item Ledger Entry Type],
            v.[Document Type]
     ) ve_fl --value entry first line
 on
    (
        ve.[Document No_] = ve_fl.[Document No_]
 	and ve.[Document Line No_] = ve_fl.[Document Line No_]
 	and ve.[Posting Date] = ve_fl.[Posting Date]
 	and ve.[Adjustment] = ve_fl.[Adjustment]
    and ve.[Item Ledger Entry Type] = ve_fl.[Item Ledger Entry Type]
    and ve.[Document Type] = ve_fl.[Document Type]
    )
left join
    [dbo].[NL$Sales Invoice Line] sil
on
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sil.[Document No_] 
    and ve.[Document Line No_] = sil.[Line No_]
    and ve.[Adjustment] = 0
    )
left join
    [dbo].[NL$Sales Invoice Header] sih
on 
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sih.[No_]
    )
left join
    [dbo].[NL$Sales Invoice Line] sil_adj
on
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sil_adj.[Document No_] 
    and ve.[Document Line No_] = sil_adj.[Line No_]
    and ve.[Adjustment] = 1
    )
left join
    [dbo].[NL$Sales Cr_Memo Line] scl
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = scl.[Document No_] 
    and ve.[Document Line No_] = scl.[Line No_]
    and ve.[Adjustment] = 0
    )
left join
    [dbo].[NL$Sales Cr_Memo Header] sch
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = sch.[No_]
    )
left join
    [dbo].[NL$Sales Cr_Memo Line] scl_adj
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = scl_adj.[Document No_] 
    and ve.[Document Line No_] = scl_adj.[Line No_]
    and ve.[Adjustment] = 1
    )
 cross apply
     (
        select 
            case ve.[Document Type]  
                when 2 then sih.[Sell-to Customer No_] 
                when 4 then sch.[Sell-to Customer No_] 
            end [Sell-to Customer No_],
            case ve.[Document Type] when 2 then sih.[Ship-to Name] when 4 then sch.[Ship-to Name] end [Ship-to Name],
            case ve.[Document Type] when 2 then sih.[Channel Code] when 4 then sch.[Channel Code] end [Channel Code],
            case ve.[Document Type] when 2 then sih.[Campaign No_] when 4 then sch.[Campaign No_] end [Campaign No_],
            case ve.[Document Type] when 2 then sih.[Media Code] when 4 then sch.[Media Code] end [Media Code],
            sih.[Order Date] dgdOrderDate,
            isnull(nullif(case ve.[Document Type] when 2 then sih.[Currency Factor] when 4 then sch.[Currency Factor] end,0),1) [Currency Factor],
            isnull(
                    nullif(
                        case ve.[Document Type] 
                                when 2 then sih.[Currency Code] 
                                when 4 then sch.[Currency Code] 
                            end
                            ,''
                        ),(select [LCY Code] from [dbo].[NL$General Ledger Setup] gls)
                     ) 
                    [Currency Code],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Amount Including VAT] when 4 then -scl.[Amount Including VAT] end else 0 end,0) [Amount Including VAT], 
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Amount] when 4 then -scl.[Amount] end else 0 end,0) [Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Line Discount Amount] when 4 then -scl.[Line Discount Amount] end else 0 end,0) [Line Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Promotion Discount Amount] when 4 then -scl.[Promotion Discount Amount] end else 0 end,0) [Promotion Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Manual Discount Amount] when 4 then -scl.[Manual Discount Amount] end else 0 end,0) [Manual Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[System Discount Amount] when 4 then -scl.[System Discount Amount] end else -0 end,0) [System Discount Amount],
            case ve.[Document Type] 
                when 2 then sil.[No_] 
                when 4 then scl.[No_] 
            end No_,
            case ve.[Document Type] 
                when 2 then sil.[Posting Date] 
                when 4 then scl.[Posting Date] 
            end [Posting Date],
            case ve.[Document Type] 
                when 2 then sih.[Ship-to Country_Region Code] 
                when 4 then sch.[Ship-to Country_Region Code] 
            end [Ship-to Country_Region Code],
             case ve.[Document Type] 
                when 2 then 
                    case ve.[Adjustment] when 0 then sil.[VAT Bus_ Posting Group] when 1 then sil_adj.[VAT Bus_ Posting Group] end
                when 4 then 
                    case ve.[Adjustment] when 0 then scl.[VAT Bus_ Posting Group] when 1 then scl_adj.[VAT Bus_ Posting Group] end 
             end [VAT Bus_ Posting Group],
             case ve.[Document Type] 
                when 2 then 
                    case ve.[Adjustment] when 0 then sil.[VAT Prod_ Posting Group] when 1 then sil_adj.[VAT Prod_ Posting Group] end
                when 4 then 
                    case ve.[Adjustment] when 0 then scl.[VAT Prod_ Posting Group] when 1 then scl_adj.[VAT Prod_ Posting Group] end 
             end [VAT Prod_ Posting Group]
     ) bridge
cross apply
    (
        select
            0 [is_amazonFBA],
            0 [is_amazonShipment],
            case when ve.[Document Type] = 2 then 1 when ve.[Document Type] = 4 then 2 else 999 end key_DocumentType,
            case when sih.[Order No_] is null then 0 else case when len(sih.[Order No_]) = 0 then 1 else 0 end end [is_honesty],
            case when -ve.[Cost Posted to G_L] > db_sys.fn_divide(bridge.Amount,bridge.[Currency Factor],default) then 1 else 0 end is_discountSale
    ) options
left join
    [dbo].[NL$Media Code] mc
on
    (
        bridge.[Media Code] = mc.Code
    )
 where
    (
        ve.[Document Type] in (2,4)
    )

union all

--NZ
select
    ve._partition [model_partition],
        (5*power(10,7))+
        (options.key_DocumentType*power(10,6))+
        (options.is_discountSale)*power(10,5)+
        (    case when is_discountSale = 1 then
                case
                    when left(mc.Audience,5) = 'STAFF' then 2
                    else 3
                end
            else 0 end
        )*(power(10,4))+
        (options.is_honesty*power(10,3))+
        (options.[is_amazonFBA]*(power(10,2)))+
        (options.is_amazonShipment*10)+
        ve.[Adjustment] key_option,
 	datediff(month,bridge.dgdOrderDate,ve.[Posting Date]) key_InvoiceLeadTime_Month,
    datediff(year,bridge.dgdOrderDate,ve.[Posting Date]) key_InvoiceLeadTime_Year,
 	(select ID from ext.Location where Location.company_id = 1 and ve.[Location Code] = Location.location_code) [keyLocation],
    hs_identity.fn_Customer(5,bridge.[Sell-to Customer No_]) keyCustomer,
    (select ID from ext.Item where Item.company_id = 1 and Item.No_ = ve.[Item No_]) [keySKU],
 	convert(date,ve.[Posting Date]) [keyInvoiceDate],
    ext.fn_Channel(1,isnull(nullif(bridge.[Channel Code],''),'PHONE')) keyChannel,
    (select ID from ext.Campaign where Campaign.company_id = 1 and Campaign.campaign_code = bridge.[Campaign No_]) keyCampaign,
    ext.fn_Media_Code(1,nullif(bridge.[Media Code],'')) keyMedia,
    isnull((select ID from ext.Country_Region where Country_Region.company_id = 1 and Country_Region.country_code = bridge.[Ship-to Country_Region Code]),-1) [keyCountryCode],
    case when (select [Customer Type] from [NZ$Customer] c where c.No_ = bridge.[Sell-to Customer No_]) = 'B2B_PARTNR' then bridge.[Ship-to Name] end [Customer Name],
    bridge.dgdOrderDate,
    (5*10000)+ve.[Dimension Set ID] [keyDimensionSetID],
    ext.fn_VAT_Posting_Setup(1,bridge.[VAT Bus_ Posting Group],bridge.[VAT Prod_ Posting Group]) keyVATPostingSetup,
 	ext.fn_Currency(bridge.[Currency Code]) [keyCurrency],
    (select ID from ext.Return_Reason rr where rr.company_id = 1 and rr.code = scl.[Return Reason Code]) [keyReturnReasonCode],
    -ve.[Invoiced Quantity] [Quantity],
 	-ext.fn_Convert_Currency_GBP(ve.[Cost Posted to G_L],5,ve.[Posting Date]) [CostPosted],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Line Discount Amount],bridge.[Currency Factor],default),5,ve.[Posting Date]) [Total Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Promotion Discount Amount],bridge.[Currency Factor],default),5,ve.[Posting Date]) [Promotion Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[System Discount Amount],bridge.[Currency Factor],default),5,ve.[Posting Date]) [System Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Manual Discount Amount],bridge.[Currency Factor],default),5,ve.[Posting Date]) [Manual Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Amount Including VAT],bridge.[Currency Factor],default),5,ve.[Posting Date]) [Gross Sales Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.Amount,bridge.[Currency Factor],default),5,ve.[Posting Date]) [Net Sales Amount (LCY)],
    isnull(-ve.[Invoiced Quantity]*ext.fn_sales_price_GBP(5,bridge.[No_],bridge.[Posting Date],'FULLPRICES'),0) [_RRP],
 	case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Amount Including VAT] end [Gross Sales Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Amount] end [Net Sales Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Line Discount Amount] end [Total Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Promotion Discount Amount] end [Promotion Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Manual Discount Amount] end [Manual Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[System Discount Amount] end [System Discount Amount (FCY)]
 from
     (
         select
            p._partition,
            [Document No_],
            [Document Line No_],
            [Posting Date],
            [Adjustment],
            [Item Ledger Entry Type],
            [Document Type],
            [Location Code],
            [Item No_],
            [Item Ledger Entry No_],
            [Dimension Set ID],
            [Document Date],
            [Entry No_],
            [Invoiced Quantity],
            [Cost Posted to G_L],
            [Discount Amount],
            [Sales Amount (Actual)]
         from
            [dbo].[NZ$Value Entry] ve
        join
            db_sys.model_partition_month p
        on
            (
                year(ve.[Posting Date]) = p._year
            and month(ve.[Posting Date]) = p._month
            )
         where
            (
                [Item Ledger Entry Type] = 1 
            and [Document Type] in (2,4)
            and ve.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
            )
      ) ve
cross apply
    [dbo].[NZ$General Ledger Setup] gls
  left join
     (
         select
            v.[Document No_],
 			v.[Document Line No_],
 			v.[Posting Date],
 			v.[Adjustment],
            v.[Item Ledger Entry Type],
            v.[Document Type],
            min(v.[Entry No_]) [Entry No_]
         from
            [dbo].[NZ$Value Entry] v
         where
            (
                v.[Item Ledger Entry Type] = 1
            and v.[Document Type] in (2,4)
            )
         group by
            v.[Document No_],
 			v.[Document Line No_],
 			v.[Posting Date],
 			v.[Adjustment],
            v.[Item Ledger Entry Type],
            v.[Document Type]
     ) ve_fl --value entry first line
 on
    (
        ve.[Document No_] = ve_fl.[Document No_]
 	and ve.[Document Line No_] = ve_fl.[Document Line No_]
 	and ve.[Posting Date] = ve_fl.[Posting Date]
 	and ve.[Adjustment] = ve_fl.[Adjustment]
    and ve.[Item Ledger Entry Type] = ve_fl.[Item Ledger Entry Type]
    and ve.[Document Type] = ve_fl.[Document Type]
    )
left join
    [dbo].[NZ$Sales Invoice Line] sil
on
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sil.[Document No_] 
    and ve.[Document Line No_] = sil.[Line No_]
    and ve.[Adjustment] = 0
    )
left join
    [dbo].[NZ$Sales Invoice Header] sih
on 
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sih.[No_]
    )
left join
    [dbo].[NZ$Sales Invoice Line] sil_adj
on
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sil_adj.[Document No_] 
    and ve.[Document Line No_] = sil_adj.[Line No_]
    and ve.[Adjustment] = 1
    )
left join
    [dbo].[NZ$Sales Cr_Memo Line] scl
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = scl.[Document No_] 
    and ve.[Document Line No_] = scl.[Line No_]
    and ve.[Adjustment] = 0
    )
left join
    [dbo].[NZ$Sales Cr_Memo Header] sch
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = sch.[No_]
    )
left join
    [dbo].[NZ$Sales Cr_Memo Line] scl_adj
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = scl_adj.[Document No_] 
    and ve.[Document Line No_] = scl_adj.[Line No_]
    and ve.[Adjustment] = 1
    )
 cross apply
     (
        select 
            case ve.[Document Type]  
                when 2 then sih.[Sell-to Customer No_] 
                when 4 then sch.[Sell-to Customer No_] 
            end [Sell-to Customer No_],
            case ve.[Document Type] when 2 then sih.[Ship-to Name] when 4 then sch.[Ship-to Name] end [Ship-to Name],
            case ve.[Document Type] when 2 then sih.[Channel Code] when 4 then sch.[Channel Code] end [Channel Code],
            case ve.[Document Type] when 2 then sih.[Campaign No_] when 4 then sch.[Campaign No_] end [Campaign No_],
            case ve.[Document Type] when 2 then sih.[Media Code] when 4 then sch.[Media Code] end [Media Code],
            sih.[Order Date] dgdOrderDate,
            isnull(nullif(case ve.[Document Type] when 2 then sih.[Currency Factor] when 4 then sch.[Currency Factor] end,0),1) [Currency Factor],
            isnull(
                    nullif(
                        case ve.[Document Type] 
                                when 2 then sih.[Currency Code] 
                                when 4 then sch.[Currency Code] 
                            end
                            ,''
                        ),(select [LCY Code] from [dbo].[NZ$General Ledger Setup] gls)
                     ) 
                    [Currency Code],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Amount Including VAT] when 4 then -scl.[Amount Including VAT] end else 0 end,0) [Amount Including VAT], 
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Amount] when 4 then -scl.[Amount] end else 0 end,0) [Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Line Discount Amount] when 4 then -scl.[Line Discount Amount] end else 0 end,0) [Line Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Promotion Discount Amount] when 4 then -scl.[Promotion Discount Amount] end else 0 end,0) [Promotion Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Manual Discount Amount] when 4 then -scl.[Manual Discount Amount] end else 0 end,0) [Manual Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[System Discount Amount] when 4 then -scl.[System Discount Amount] end else -0 end,0) [System Discount Amount],
            case ve.[Document Type] 
                when 2 then sil.[No_] 
                when 4 then scl.[No_] 
            end No_,
            case ve.[Document Type] 
                when 2 then sil.[Posting Date] 
                when 4 then scl.[Posting Date] 
            end [Posting Date],
            case ve.[Document Type] 
                when 2 then sih.[Ship-to Country_Region Code] 
                when 4 then sch.[Ship-to Country_Region Code] 
            end [Ship-to Country_Region Code],
             case ve.[Document Type] 
                when 2 then 
                    case ve.[Adjustment] when 0 then sil.[VAT Bus_ Posting Group] when 1 then sil_adj.[VAT Bus_ Posting Group] end
                when 4 then 
                    case ve.[Adjustment] when 0 then scl.[VAT Bus_ Posting Group] when 1 then scl_adj.[VAT Bus_ Posting Group] end 
             end [VAT Bus_ Posting Group],
             case ve.[Document Type] 
                when 2 then 
                    case ve.[Adjustment] when 0 then sil.[VAT Prod_ Posting Group] when 1 then sil_adj.[VAT Prod_ Posting Group] end
                when 4 then 
                    case ve.[Adjustment] when 0 then scl.[VAT Prod_ Posting Group] when 1 then scl_adj.[VAT Prod_ Posting Group] end 
             end [VAT Prod_ Posting Group]
     ) bridge
cross apply
    (
        select
            0 [is_amazonFBA],
            0 [is_amazonShipment],
            case when ve.[Document Type] = 2 then 1 when ve.[Document Type] = 4 then 2 else 999 end key_DocumentType,
            case when sih.[Order No_] is null then 0 else case when len(sih.[Order No_]) = 0 then 1 else 0 end end [is_honesty],
            case when -ve.[Cost Posted to G_L] > db_sys.fn_divide(bridge.Amount,bridge.[Currency Factor],default) then 1 else 0 end is_discountSale
    ) options
left join
    [dbo].[NZ$Media Code] mc
on
    (
        bridge.[Media Code] = mc.Code
    )
 where
    (
        ve.[Document Type] in (2,4)
    )

union all

--IE
select
    ve._partition [model_partition],
        (6*power(10,7))+
        (options.key_DocumentType*power(10,6))+
        (options.is_discountSale)*power(10,5)+
        (    case when is_discountSale = 1 then
                case
                    when left(mc.Audience,5) = 'STAFF' then 2
                    else 3
                end
            else 0 end
        )*(power(10,4))+
        (options.is_honesty*power(10,3))+
        (options.[is_amazonFBA]*(power(10,2)))+
        (options.is_amazonShipment*10)+
        ve.[Adjustment] key_option,
 	datediff(month,bridge.dgdOrderDate,ve.[Posting Date]) key_InvoiceLeadTime_Month,
    datediff(year,bridge.dgdOrderDate,ve.[Posting Date]) key_InvoiceLeadTime_Year,
 	(select ID from ext.Location where Location.company_id = 1 and ve.[Location Code] = Location.location_code) [keyLocation],
    hs_identity.fn_Customer(6,bridge.[Sell-to Customer No_]) keyCustomer,
    (select ID from ext.Item where Item.company_id = 1 and Item.No_ = ve.[Item No_]) [keySKU],
 	convert(date,ve.[Posting Date]) [keyInvoiceDate],
    ext.fn_Channel(1,isnull(nullif(bridge.[Channel Code],''),'PHONE')) keyChannel,
    (select ID from ext.Campaign where Campaign.company_id = 1 and Campaign.campaign_code = bridge.[Campaign No_]) keyCampaign,
    ext.fn_Media_Code(1,nullif(bridge.[Media Code],'')) keyMedia,
    isnull((select ID from ext.Country_Region where Country_Region.company_id = 1 and Country_Region.country_code = bridge.[Ship-to Country_Region Code]),-1) [keyCountryCode],
    case when (select [Customer Type] from [IE$Customer] c where c.No_ = bridge.[Sell-to Customer No_]) = 'B2B_PARTNR' then bridge.[Ship-to Name] end [Customer Name],
    bridge.dgdOrderDate,
    (6*10000)+ve.[Dimension Set ID] [keyDimensionSetID],
    ext.fn_VAT_Posting_Setup(1,bridge.[VAT Bus_ Posting Group],bridge.[VAT Prod_ Posting Group]) keyVATPostingSetup,
 	ext.fn_Currency(bridge.[Currency Code]) [keyCurrency],
    (select ID from ext.Return_Reason rr where rr.company_id = 1 and rr.code = scl.[Return Reason Code]) [keyReturnReasonCode],
    -ve.[Invoiced Quantity] [Quantity],
 	-ext.fn_Convert_Currency_GBP(ve.[Cost Posted to G_L],6,ve.[Posting Date]) [CostPosted],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Line Discount Amount],bridge.[Currency Factor],default),6,ve.[Posting Date]) [Total Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Promotion Discount Amount],bridge.[Currency Factor],default),6,ve.[Posting Date]) [Promotion Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[System Discount Amount],bridge.[Currency Factor],default),6,ve.[Posting Date]) [System Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Manual Discount Amount],bridge.[Currency Factor],default),6,ve.[Posting Date]) [Manual Discount Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.[Amount Including VAT],bridge.[Currency Factor],default),6,ve.[Posting Date]) [Gross Sales Amount (LCY)],
    ext.fn_Convert_Currency_GBP(db_sys.fn_divide(bridge.Amount,bridge.[Currency Factor],default),6,ve.[Posting Date]) [Net Sales Amount (LCY)],
    isnull(-ve.[Invoiced Quantity]*ext.fn_sales_price_GBP(6,bridge.[No_],bridge.[Posting Date],'FULLPRICES'),0) [_RRP],
 	case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Amount Including VAT] end [Gross Sales Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Amount] end [Net Sales Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Line Discount Amount] end [Total Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Promotion Discount Amount] end [Promotion Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[Manual Discount Amount] end [Manual Discount Amount (FCY)],
    case when bridge.[Currency Code] = gls.[LCY Code] then 0 else bridge.[System Discount Amount] end [System Discount Amount (FCY)]
 from
     (
         select
            p._partition,
            [Document No_],
            [Document Line No_],
            [Posting Date],
            [Adjustment],
            [Item Ledger Entry Type],
            [Document Type],
            [Location Code],
            [Item No_],
            [Item Ledger Entry No_],
            [Dimension Set ID],
            [Document Date],
            [Entry No_],
            [Invoiced Quantity],
            [Cost Posted to G_L],
            [Discount Amount],
            [Sales Amount (Actual)]
         from
            [dbo].[IE$Value Entry] ve
        join
            db_sys.model_partition_month p
        on
            (
                year(ve.[Posting Date]) = p._year
            and month(ve.[Posting Date]) = p._month
            )
         where
            (
                [Item Ledger Entry Type] = 1 
            and [Document Type] in (2,4)
            and ve.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
            )
      ) ve
cross apply
    [dbo].[IE$General Ledger Setup] gls
  left join
     (
         select
            v.[Document No_],
 			v.[Document Line No_],
 			v.[Posting Date],
 			v.[Adjustment],
            v.[Item Ledger Entry Type],
            v.[Document Type],
            min(v.[Entry No_]) [Entry No_]
         from
            [dbo].[IE$Value Entry] v
         where
            (
                v.[Item Ledger Entry Type] = 1
            and v.[Document Type] in (2,4)
            )
         group by
            v.[Document No_],
 			v.[Document Line No_],
 			v.[Posting Date],
 			v.[Adjustment],
            v.[Item Ledger Entry Type],
            v.[Document Type]
     ) ve_fl --value entry first line
 on
    (
        ve.[Document No_] = ve_fl.[Document No_]
 	and ve.[Document Line No_] = ve_fl.[Document Line No_]
 	and ve.[Posting Date] = ve_fl.[Posting Date]
 	and ve.[Adjustment] = ve_fl.[Adjustment]
    and ve.[Item Ledger Entry Type] = ve_fl.[Item Ledger Entry Type]
    and ve.[Document Type] = ve_fl.[Document Type]
    )
left join
    [dbo].[IE$Sales Invoice Line] sil
on
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sil.[Document No_] 
    and ve.[Document Line No_] = sil.[Line No_]
    and ve.[Adjustment] = 0
    )
left join
    [dbo].[IE$Sales Invoice Header] sih
on 
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sih.[No_]
    )
left join
    [dbo].[IE$Sales Invoice Line] sil_adj
on
    (
        ve.[Document Type] = 2
    and ve.[Document No_] = sil_adj.[Document No_] 
    and ve.[Document Line No_] = sil_adj.[Line No_]
    and ve.[Adjustment] = 1
    )
left join
    [dbo].[IE$Sales Cr_Memo Line] scl
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = scl.[Document No_] 
    and ve.[Document Line No_] = scl.[Line No_]
    and ve.[Adjustment] = 0
    )
left join
    [dbo].[IE$Sales Cr_Memo Header] sch
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = sch.[No_]
    )
left join
    [dbo].[IE$Sales Cr_Memo Line] scl_adj
on
    (
        ve.[Document Type] = 4
    and ve.[Document No_] = scl_adj.[Document No_] 
    and ve.[Document Line No_] = scl_adj.[Line No_]
    and ve.[Adjustment] = 1
    )
 cross apply
     (
        select 
            case ve.[Document Type]  
                when 2 then sih.[Sell-to Customer No_] 
                when 4 then sch.[Sell-to Customer No_] 
            end [Sell-to Customer No_],
            case ve.[Document Type] when 2 then sih.[Ship-to Name] when 4 then sch.[Ship-to Name] end [Ship-to Name],
            case ve.[Document Type] when 2 then sih.[Channel Code] when 4 then sch.[Channel Code] end [Channel Code],
            case ve.[Document Type] when 2 then sih.[Campaign No_] when 4 then sch.[Campaign No_] end [Campaign No_],
            case ve.[Document Type] when 2 then sih.[Media Code] when 4 then sch.[Media Code] end [Media Code],
            sih.[Order Date] dgdOrderDate,
            isnull(nullif(case ve.[Document Type] when 2 then sih.[Currency Factor] when 4 then sch.[Currency Factor] end,0),1) [Currency Factor],
            isnull(
                    nullif(
                        case ve.[Document Type] 
                                when 2 then sih.[Currency Code] 
                                when 4 then sch.[Currency Code] 
                            end
                            ,''
                        ),(select [LCY Code] from [dbo].[IE$General Ledger Setup] gls)
                     ) 
                    [Currency Code],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Amount Including VAT] when 4 then -scl.[Amount Including VAT] end else 0 end,0) [Amount Including VAT], 
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Amount] when 4 then -scl.[Amount] end else 0 end,0) [Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Line Discount Amount] when 4 then -scl.[Line Discount Amount] end else 0 end,0) [Line Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Promotion Discount Amount] when 4 then -scl.[Promotion Discount Amount] end else 0 end,0) [Promotion Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[Manual Discount Amount] when 4 then -scl.[Manual Discount Amount] end else 0 end,0) [Manual Discount Amount],
            isnull(case when ve.[Entry No_] = ve_fl.[Entry No_] then case ve.[Document Type] when 2 then sil.[System Discount Amount] when 4 then -scl.[System Discount Amount] end else -0 end,0) [System Discount Amount],
            case ve.[Document Type] 
                when 2 then sil.[No_] 
                when 4 then scl.[No_] 
            end No_,
            case ve.[Document Type] 
                when 2 then sil.[Posting Date] 
                when 4 then scl.[Posting Date] 
            end [Posting Date],
            case ve.[Document Type] 
                when 2 then sih.[Ship-to Country_Region Code] 
                when 4 then sch.[Ship-to Country_Region Code] 
            end [Ship-to Country_Region Code],
             case ve.[Document Type] 
                when 2 then 
                    case ve.[Adjustment] when 0 then sil.[VAT Bus_ Posting Group] when 1 then sil_adj.[VAT Bus_ Posting Group] end
                when 4 then 
                    case ve.[Adjustment] when 0 then scl.[VAT Bus_ Posting Group] when 1 then scl_adj.[VAT Bus_ Posting Group] end 
             end [VAT Bus_ Posting Group],
             case ve.[Document Type] 
                when 2 then 
                    case ve.[Adjustment] when 0 then sil.[VAT Prod_ Posting Group] when 1 then sil_adj.[VAT Prod_ Posting Group] end
                when 4 then 
                    case ve.[Adjustment] when 0 then scl.[VAT Prod_ Posting Group] when 1 then scl_adj.[VAT Prod_ Posting Group] end 
             end [VAT Prod_ Posting Group]
     ) bridge
cross apply
    (
        select
            0 [is_amazonFBA],
            0 [is_amazonShipment],
            case when ve.[Document Type] = 2 then 1 when ve.[Document Type] = 4 then 2 else 999 end key_DocumentType,
            case when sih.[Order No_] is null then 0 else case when len(sih.[Order No_]) = 0 then 1 else 0 end end [is_honesty],
            case when -ve.[Cost Posted to G_L] > db_sys.fn_divide(bridge.Amount,bridge.[Currency Factor],default) then 1 else 0 end is_discountSale
    ) options
left join
    [dbo].[IE$Media Code] mc
on
    (
        bridge.[Media Code] = mc.Code
    )
 where
    (
        ve.[Document Type] in (2,4)
    )
GO
