create or alter view price_tool_feed.vw_export_pricelist_post

as

select
    f.blob_name [File],
    z.zone_name [Zone],
    p.price_type [Price Type],
    i.[No_] [Item Code],
    format((select max(d) from (values (ip.valid_from),(dateadd(day,1,convert(date,getutcdate())))) as value(d)),'dd/MM/yyyy') [Valid From],
    format(isnull(ip.valid_to,datefromparts(2099,12,31)),'dd/MM/yyyy') [Valid To],
    format(ip.price,'c','en-GB') [Price]
from
    price_tool_feed.import_pricelist ip
join
    price_tool_feed.import_filelist f
on
    (
        ip.filelist_id = f.id
    )
join
    price_tool_feed.import_pricetype p
on
    (
        ip.pricetype_id = p.id
    )
join
    ext.Item i
on
    (
        ip.item_id = i.ID
    )
join
    price_tool_feed.zones z
on
    (
        ip.zone_id = z.zone_id
    )
where
    (
        ip.is_in_next_post = 1
    )

