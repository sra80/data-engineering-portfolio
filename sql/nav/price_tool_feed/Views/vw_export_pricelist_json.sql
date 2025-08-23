create or alter view price_tool_feed.vw_export_pricelist_json

as

with cte as
    (
        select
            0 [Status],
            0 [Ignored],
            '' [Error Msg], 
            e_i.No_ [Item No_],
            e_cpg.code [Sales Code],
            '' [Currency Code],
            convert(datetime,y_ep.valid_from) [Starting Date],
            convert(decimal(38,20),y_ep.price) [Unit Price],
            1 [Price Includes VAT],
            1 [Allow Invoice Disc_],
            1 [Sales Type],
            convert(decimal(38,20),0) [Minimum Quantity],
            convert(datetime,y_ep.valid_to) [Ending Date],
            '' [Unit of Measure Code],
            '' [Variant Code],
            convert(tinyint,1) [Allow Line Disc_],
            0 [Price Approved],
            getutcdate() [Created Date_Time],
            lower(y_ep.external_id) external_id,
            row_number() over (order by y_ep.item_id, y_ep.price_group_id, y_ep.valid_from) orderby
        from 
            price_tool_feed.export_pricelist2 y_ep
        join
            ext.Item e_i
        on
            (
                y_ep.item_id = e_i.ID
            )
        join 
            ext.Customer_Price_Group e_cpg 
        on 
            (
                y_ep.price_group_id = e_cpg.id
            )
        join
            price_tool_feed.export_pricelist_vc y_epv
        on
            (
                y_ep.vc_id = y_epv.id
            )
        where
            (
                y_ep.external_id not in (select isnull(try_convert(uniqueidentifier,[External ID]),0x0) from [dbo].[UK$Sales Price Holding Table] where [Status] != 2)
            and y_epv.is_current = 1
            )
    )

select
    (
        select * from cte for json auto
    ) _json