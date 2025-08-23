
create   view [marketing].[PaymentMethod]

as

select 
	e.ID [Code]
   ,[Description] [Payment Method]
from
	hs_consolidated.[Payment Method] h
join
    ext.Payment_Method e
on
    (
        h.company_id = e.company_id
    and h.Code = e.pm_code
    )

union all

select
    e.ID,
    'Payment Method Unknown'
from
    ext.Payment_Method e
where
    pm_code = 'unknown'
GO
