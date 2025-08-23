create or alter function db_sys.fn_email_split_internal_external
    (
        @email_list nvarchar(max)
    )

returns table

as

return

select
    string_agg(case when is_internal = 1 then email_list else null end,'; ') email_internal,
    string_agg(case when is_internal = 0 then email_list else null end,'; ') email_external
from
    (
        select
            ltrim(rtrim(value)) email_list,
            case when lower(value) like '%CompanyX.co.uk%' then 1 else 0 end is_internal
        from
            string_split(@email_list,';')
    ) sub_q