--finance.Company (new) *done*
create   view finance.Company

as

select
    ID company_id,
    Company
from
    db_sys.Company
where
    is_excluded = 0
GO
