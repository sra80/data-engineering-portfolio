create   view finance.[VAT_Posting_Setup]

as


select 
    e.id keyVATPostingSetup,
    h.[VAT Bus_ Posting Group] [VAT Business Posting Group],
    h.[VAT Prod_ Posting Group] [VAT Product Posting Group],
    h.[VAT _] [VAT Rate]
from 
    ext.VAT_Posting_Setup e 
join 
    hs_consolidated.[VAT Posting Setup] h
on
    (
        e.company_id = h.company_id
    and e.Bus_Posting_Group = h.[VAT Bus_ Posting Group]
    and e.Prod_Posting_Group = h.[VAT Prod_ Posting Group]
    )
GO
