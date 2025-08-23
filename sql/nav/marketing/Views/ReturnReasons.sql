
create   view [marketing].[ReturnReasons]

as

select
	e.ID [Code]
   ,case 
		when left(h.[Code],1) = 'O' then 'Order'
		when left(h.[Code],1) = 'P' then 'Postal'
		when left(h.[Code],2) = 'QA' then 'Objective Quality'
		when left(h.[Code],2) = 'QB' then 'Subjective Quality'
    end [Return Type]
   ,substring(h.[Description],5,45) [Return Reason]
from
	hs_consolidated.[Return Reason] h
join
    ext.Return_Reason e
on
    (
        h.company_id = e.company_id
    and h.Code = e.code
    )
GO
