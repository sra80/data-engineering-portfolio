CREATE procedure marketing.sp_CSH_Moving_Extended_Item_initial

as

declare @rowcount int = 1

while @rowcount > 0

begin

set nocount on

declare @t table (No_ nvarchar(20), [Start Date] date, [End Date] date, [Status Start Date] date, [Status End Date] date, [Status] int, [Opt In] bit, Ecosystem int, opt_source_key int, eco_state_change bit, opt_state_change bit)

insert into @t (No_, [Start Date], [End Date], [Status Start Date], [Status End Date], [Status], [Opt In], Ecosystem, opt_source_key, eco_state_change, opt_state_change)
select top 10000 [No_], [Start Date], [End Date], [Status Start Date], [Status End Date], [Status], [Opt In], Ecosystem, opt_source_key, eco_state_change, opt_state_change from marketing.CSH_Moving_Extended where [Status] < 4 and update_CSH_Moving_Extended_Item = 1 and No_ in (select cus from ext.Customer)

set @rowcount = @@rowcount

insert into marketing.CSH_Moving_Extended_Item  (cus_ID,_start_date,channel_ID,sku_ID,_end_date,_start_date_status,_end_date_status,sku_last_order,first_order_cus,first_order_range,first_order_sku,_status,opt_in_email,ecosystem,opt_source_key,eco_state_change,opt_state_change)
select 
    (select ID from ext.Customer where cus = cme.No_) cus_ID,
    cme.[Start Date] _start_date,
    isnull((select ID from ext.Channel where Channel_Code = sales.channel_code),0) channel_ID,
    isnull((select ID from ext.Item where No_ = sales.sku),0) sku_ID,
    cme.[End Date] _end_date,
    cme.[Status Start Date] _start_date_status,
    cme.[Status End Date] _end_date_status,
    sales.sku_last_order,
    (select min(first_order) from ext.Customer_Item_Summary cis where cis.cus = cme.No_) first_order_cus,
    (
        select 
            min(cis1.first_order)
        from
            ext.Customer_Item_Summary cis0
        join
            dbo.Item i0
        on
            (
                cis0.sku = i0.No_
            )
        join
            dbo.Item i1
        on
            i0.[Range Code] = i1.[Range Code]
        join
            ext.Customer_Item_Summary cis1
        on
            (
                cis0.cus = cis1.cus
            and i1.No_ = cis1.sku
            )
        where
            cis0.cus = cme.No_
            and cis0.sku = sales.sku
    ) first_order_range,
    (select first_order from ext.Customer_Item_Summary cis where cme.No_ = cis.cus and sales.sku = cis.sku) first_order_sku,
    cme.[Status] _status,
    cme.[Opt In] opt_in_email,
    cme.Ecosystem ecosystem,
    cme.opt_source_key,
    cme.eco_state_change,
    cme.opt_state_change
from 
    @t cme
outer apply
    (
        select
            sku,
            channel_code,
            min(order_date) sku_first_order,
            max(order_date) sku_last_order
        from
            (
                select
                    x.order_date,
                    x.sku,
                x.channel_code 
                from
                    (
                    select 
                            convert(date,h.[Order Date]) order_date,
                            h.[Sell-to Customer No_] cus,
                            coalesce(nullif(h.[Channel Code],''),'PHONE') channel_code,
                            l.No_ sku
                        from
                            ext.Sales_Header h
                        join
                            ext.Sales_Line l
                        on
                            (
                                h.No_ = l.[Document No_]
                            and h.[Document Type] = l.[Document Type]
                            )
                        where
                            (
                                h.[Sales Order Status] = 1
                            and h.[Sell-to Customer No_] = cme.No_
                            and h.[Order Date] >= dateadd(year,-1,cme.[Status Start Date])
                            and h.[Order Date] <= isnull(cme.[Status End Date],convert(date,getutcdate()))
                            )

                        union all

                        select
                            convert(date,h.[Order Date]) order_date,
                            h.[Sell-to Customer No_] cus,
                            coalesce(nullif(h.[Channel Code],''),'PHONE') channel_code,
                            l.No_ sku
                        from
                            ext.Sales_Header_Archive h
                        join
                            ext.Sales_Line_Archive l
                        on
                            (
                                h.No_ = l.[Document No_]
                            and h.[Document Type] = l.[Document Type]
                            and h.[Doc_ No_ Occurrence] = l.[Doc_ No_ Occurrence]
                            and h.[Version No_] = l.[Version No_]
                            )
                        where
                            (
                                h.[Sell-to Customer No_] = cme.No_
                            and h.[Order Date] >= dateadd(year,-1,cme.[Status Start Date])
                            and h.[Order Date] <= isnull(cme.[Status End Date],convert(date,getutcdate()))
                            )
                        ) x
                    where
                        (   
                            len(x.sku) > 0
                        )
            ) agg
        group by
            sku,
            channel_code
    ) sales

update e set e.update_CSH_Moving_Extended_Item = 0 from marketing.CSH_Moving_Extended e join @t t on e.[No_] = t.[No_] and e.[Start Date] = t.[Start Date]

delete from @t

end
GO
