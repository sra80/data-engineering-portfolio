create or alter function ext.fn_amazon_import_filename
    (
        @file_name nvarchar(255)
    )

returns nvarchar(255)

as

begin

select
    @file_name = t.value
from
    (
        select
            s.value,
            s.ordinal,
            max(s.ordinal) over () ordinal_max
        from
            string_split(@file_name,case when charindex('/',@file_name) > 0 then '/' else '\' end, 1) s
    ) t
where
    (
        t.ordinal = t.ordinal_max
    )

return @file_name

end