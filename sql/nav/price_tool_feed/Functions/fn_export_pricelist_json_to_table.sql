create or alter function price_tool_feed.fn_export_pricelist_json_to_table
    (
        @json nvarchar(max)
    )

returns table

/*
set @json to json from price_tool_feed.vw_export_pricelist_json to convert to table output
*/

as

return

select
    [Status],
    [Ignored],
    [Error Msg],
    [Item No_],
    [Sales Code],
    [Currency Code],
    [Starting Date],
    [Unit Price],
    [Price Includes VAT],
    [Allow Invoice Disc_],
    [Sales Type],
    [Minimum Quantity],
    [Ending Date],
    [Unit of Measure Code],
    [Variant Code],
    [Allow Line Disc_],
    [Price Approved],
    [Created Date_Time],
    [external_id],
    [orderby]
from
    (
        select
            j1.[key] k1,
            j2.[key],
            j2.[value]
        from
            openjson(@json) j0
        cross apply
            openjson(j0.value) j1
        cross apply
            openjson(j1.value) j2
    ) u
pivot
    (
        min([value])
    for
        [key] in 
            (
                [Status],
                [Ignored],
                [Error Msg],
                [Item No_],
                [Sales Code],
                [Currency Code],
                [Starting Date],
                [Unit Price],
                [Price Includes VAT],
                [Allow Invoice Disc_],
                [Sales Type],
                [Minimum Quantity],
                [Ending Date],
                [Unit of Measure Code],
                [Variant Code],
                [Allow Line Disc_],
                [Price Approved],
                [Created Date_Time],
                [external_id],
                [orderby]
            )
    ) p

    