create or alter view marketing.Geographic

as

select
    id outcode_id,
    isnull(town,region) town,
    latitude,
    longitude
from
    db_sys.outcode