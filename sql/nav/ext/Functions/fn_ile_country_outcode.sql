create or alter function ext.fn_ile_country_outcode
    (
        @company_id int,
        @external_document_no_ nvarchar(35),
        @ile_doc_type int,
        @ile_entry_no int
    )

returns table

as

return

select top 1
    x.outcode_id,
    x.country_id
from
    (
        select top 1
                0 order_by,
                oc.outcode_id,
                oc.country_id
            from
                ext.amazon_import_reconciliation air
            join
                ext.amazon_import_sales_line ail
            on
                (
                    air.sales_line_id = ail.id
                )
            join
                ext.amazon_import_sales_header aih
            on
                (
                    ail.sales_header_id = aih.id
                )
            cross apply
                db_sys.fn_outcode_countrycode(@company_id, aih.ship_postal_code,aih.ship_country) oc
            where
                (
                    air.ile_entry_no = @ile_entry_no
                and @company_id = 1
                and @ile_doc_type = 0
                )

        union all

        select top 1
                1, 
                oc.outcode_id,
                oc.country_id
            from 
                hs_consolidated.[Sales Invoice Header] sih
            cross apply
                db_sys.fn_outcode_countrycode(sih.company_id, sih.[Ship-to Post Code],sih.[Ship-to Country_Region Code]) oc
            where
                (
                    sih.company_id = @company_id
                and sih.[External Document No_] = @external_document_no_
                and @ile_doc_type = 1
                )

        union all

        select top 1
                2, 
                oc.outcode_id,
                oc.country_id
            from 
                hs_consolidated.[Return Receipt Header] rrh
            cross apply
                db_sys.fn_outcode_countrycode(rrh.company_id, rrh.[Ship-to Post Code],rrh.[Ship-to Country_Region Code]) oc
            where
                (
                    rrh.company_id = @company_id
                and rrh.[External Document No_] = @external_document_no_
                and @ile_doc_type = 0
                )

        union all

        select
            3,
            -1,
            -1
    ) x
order by
    x.order_by