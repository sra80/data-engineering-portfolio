CREATE   function [forecast_feed].[fn_received_POs_ref]
    (
        @company_id int,
        @entry_type int,
        @doc_no nvarchar(20),
        @sku nvarchar(20)
    )

returns table

as

return

select
    concat([Order No_],'_',[Order Line No_]) order_no_, null prod_order_no_, null blanket_order_no_, [Anaplan Release ID] CompanyX_ref from [hs_consolidated].[Purch_ Rcpt_ Line] where company_id = @company_id and [Document No_] = @doc_no and No_ = @sku and @entry_type = 0

union all

select
    concat([Document No_],'_',[Line No_]) order_no_, [Prod_ Order No_] prod_order_no_, [Blanket Order No_] blanket_order_no_, [Anaplan Release ID] CompanyX_ref from [hs_consolidated].[Purchase Line] where company_id = @company_id and [Prod_ Order No_] = @doc_no and No_ = @sku and @entry_type = 6
GO
