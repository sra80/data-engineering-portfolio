CREATE procedure ext.sp_Customer_Item_Summary

as

/*
 Description:		Maintains ext.Customer_Item_Summary
 Project:			112
 Creator:			Shaun Edwards(SE)
 Copyright:			CompanyX Limited, 2022
MOD	DATE	INITS	COMMENTS
00  220127  SE      Created
01
02
03
04 
05 220215   SE      Current version, no version dialogue up to this point
06 220308   SE      Change cursor name from x to [55082284-a472-4147-9970-fd1f0bc543ae], close & deallocate cursor when done
*/

set nocount on

declare @cus nvarchar(32), @sku nvarchar(32)

declare [55082284-a472-4147-9970-fd1f0bc543ae] cursor for 
    (
        select  
            o.cus,
            o.sku
        from
            (
                select 
                    cus, 
                    sku, 
                    max(order_date) last_order 
                from 
                    (
                        select 
                            h.[Sell-to Customer No_] cus,
                            h.[Order Date] order_date,
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
                            )

                        union all

                        select 
                            h.[Sell-to Customer No_],
                            h.[Order Date],
                            l.No_
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
                    ) o
                group by 
                    cus, sku
            ) o
        join
            (select No_ from dbo.Item where [Type] = 0) i
        on
            (o.sku = i.No_)
        left join
            ext.Customer_Item_Summary s
        on
            (
                o.cus = s.cus
            and o.sku = s.sku
            )
        where
            (
                s.last_order < o.last_order
            or  s.last_order is null
            )
    )

open [55082284-a472-4147-9970-fd1f0bc543ae]

fetch next from [55082284-a472-4147-9970-fd1f0bc543ae] into @cus, @sku

while @@fetch_status = 0

begin

begin transaction

update t set 
    t.units = s.units,
    t.gross = s.gross,
    t.net = s.net,
    t.first_order = s.first_order,
    t.last_order = s.last_order,
    t.UpdatedTSUTC = getutcdate()
from
    ext.fn_Customer_Item_Summary(@cus,@sku) s
join
    ext.Customer_Item_Summary t
on
    (
        t.cus = @cus
    and t.sku = @sku
    )

    if @@rowcount = 0

    insert into ext.Customer_Item_Summary (cus, sku, units, gross, net, first_order, last_order)
    select @cus, @sku, units, gross, net, first_order, last_order from ext.fn_Customer_Item_Summary(@cus,@sku)

commit transaction

fetch next from [55082284-a472-4147-9970-fd1f0bc543ae] into @cus, @sku

end

close [55082284-a472-4147-9970-fd1f0bc543ae]
deallocate [55082284-a472-4147-9970-fd1f0bc543ae]
GO
