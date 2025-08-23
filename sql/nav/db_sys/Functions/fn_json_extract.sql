create function db_sys.[fn_json_extract]
    (
        @json nvarchar(max)
    )

returns table

as

return
(
    
    with j as
        (
            select 
                0 [level],
                convert(nvarchar(max),'root') [path],
                j.[key],
                j.[value],
                j.[type]
            from
                openjson(@json) j

            union all

            select
                j.[level] + 1,
                j.[path] + '/' + convert(nvarchar(max),x.[key] collate database_default), 
                x.[key], 
                x.[value], 
                x.[type]
            from
                j
            cross apply
                openjson(j.[value]) x
            where
                j.[type] in (4,5)

        )

    select
        [level],
        [path],
        [key],
        [value],
        [type]
    from
        j
    where
        [type] < 4

)
GO
