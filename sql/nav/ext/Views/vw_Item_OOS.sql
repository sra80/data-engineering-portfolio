








CREATE view [ext].[vw_Item_OOS]

as

/*
04  210216  Change logic for Ringfence Action of Review Ringfence Date
05  210301  Change logic for ring fence review to 50% threshold, rather than there being more stock than actual subs
06  210317  Change calculation of weeks out, switched unit from week to day then divide by 7 and round by 0
07  210325  Tweak to Review Ringfence Action
08	210331	Timezone alignment
09	210415	Tweak to Ringfence Action, noticed cases where there was a review rf date when rf date was the same as expected stock in date
10	210422	Added Available Stock
11	210715	Added Ringfenced Runout Date
12	210818	Remove Missing Expiry Date
*/

with c as
    (
    select 
        o.sku [Item Code]
        ,isnull(nullif(i.[Description],''),'***No Item Description***') [Item Description]
        ,case i.[Status] when 0 then 'Prelaunch' when 1 then 'Active' when 4 then 'Rundown' else 'Unknown' end [Item Status]
        ,dateadd(minute,datediff(minute,o.dateaddedUTC AT TIME ZONE isnull(tz.timezone,'GMT Standard Time'),o.dateaddedUTC),o.dateaddedUTC) [Last Forecast Update]
        ,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end [Estimated Stock Out]
        ,o.estStockIn [Estimated Stock In]
        ,o.estStockInRef [Purchase Order Ref.]
        ,nullif(convert(int,round(datediff(day,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end,o.estStockIn)/7.0,0)),0) [Weeks Stock Out]
        ,o.ringFenceItemCard [Ringfenced To]
        ,nullif(o.ringFenceQty,0) [Ringfenced Quantity]
		,case when o.ringFenceRunout >= o.estStockIn then null else o.ringFenceRunout end [Ringfenced Runout Date]
        ,o.availableStock [Opening Stock]
		,availableStock [Available Stock]
        ,nullif(o.forecastQty,0) [Forecast Sales (inc Repeats) to Next Stock In]
        ,nullif(o.subQty,0) [Forecast Repeats Actual to Next Stock In]
        ,nullif(o.awaitingQAQty,0) [Waiting for QA]
        ,case when datediff(week,dateaddedUTC,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end) < 0 then null else o.ringFenceActionDate end [Ringfence Action Date]
        ,case when datediff(week,dateaddedUTC,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end)  < -1 
            then format(-datediff(week,dateaddedUTC,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end),'#,##0')+' weeks ago'
        else
            case  datediff(week,dateaddedUTC,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end)
                when -1 then 'Last week'
                when 0 then 'This week'
                when 1 then 'Next week'
            else 
                'In ' + format(datediff(week,dateaddedUTC,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end),'#,##0')+' weeks'
            end 
        end [Stock Out]
        ,datediff(week,dateaddedUTC,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end) ord_stockOut
        ,case when o.ringFenceActionDate is null then datefromparts(2099,12,31) else o.ringFenceActionDate end ord_ringFenceActionDate
        ,dateaddedUTC
    from 
        ext.Item_OOS o
    join
        dbo.Item i
    on  
        (
            o.sku = i.No_
        )
	outer apply
		(
			select timezone from db_sys.user_config where lower(SYSTEM_USER) = lower(username)
		) tz
    where
        (
            is_current = 1
        and 
            (
                datediff(week,dateaddedUTC,case when o.availableStock < 10 and (datediff(day,o.lastPick,o.forecastRunoutDate) > 7 or o.forecastRunoutDate is null) then o.lastPick else o.forecastRunoutDate end) <= 12
            or  o.availableStock = 0
            )
        )
    )

select
     c.*
    ,case when 
            [Available Stock] > 0 and [Forecast Repeats Actual to Next Stock In] > 0 and [Ringfenced Quantity] > 0 and [Ringfenced To] is not null
        and 
            (
                (
                --    [Opening Stock] > [Forecast Repeats Actual to Next Stock In] --changed made by Shaun @ 2021-05-26T12:49:32.1269420+03:00
                --and 
					datediff(day,[Ringfenced To],[Estimated Stock In]) >= 7 
                )
            --or
            --    (
            --        [Ringfenced Quantity] > [Forecast Repeats Actual to Next Stock In]
            --    and datediff(day,[Ringfenced To],[Estimated Stock In]) >= 7 
            --    )
            or
                (
                    [Forecast Repeats Actual to Next Stock In]/convert(float,[Available Stock]) < 1.1
                and ([Forecast Repeats Actual to Next Stock In]/convert(float,[Available Stock])) > ([Ringfenced Quantity]/convert(float,[Forecast Repeats Actual to Next Stock In]))
                and abs(datediff(day,[Ringfenced To],[Estimated Stock In])) >= 7 
				)
            )
    then 'Review Ringfence Date' 
    else 
        case when 
                [Forecast Repeats Actual to Next Stock In] > 0 
            and [Available Stock] > 0 
            and [Ringfenced To] is null 
        then 
            case when 
                    [Ringfence Action Date] = convert(date,dateaddedUTC) 
                and [Forecast Repeats Actual to Next Stock In]/convert(float,[Opening Stock]) > 0.1 
            then 'Immediate' 
            else 
                case datediff(week,dateaddedUTC,[Ringfence Action Date]) 
                when 0 then 'This Week' 
                when 1 then 'Next Week' 
                else 'In ' + format(datediff(week,dateaddedUTC,[Ringfence Action Date]),'0') + ' weeks' 
                end 
            end 
        end 
    end [Ringfence Action]
    ,case when 
            [Available Stock] > 0 and [Forecast Repeats Actual to Next Stock In] > 0 and [Ringfenced Quantity] > 0 and [Ringfenced To] is not null
        and 
            (
                (
                --    [Opening Stock] > [Forecast Repeats Actual to Next Stock In]
                --and 
				datediff(day,[Ringfenced To],[Estimated Stock In]) >= 7 
                )
            --or
            --    (
            --        [Ringfenced Quantity] > [Forecast Repeats Actual to Next Stock In]
            --    and datediff(day,[Ringfenced To],[Estimated Stock In]) >= 7 
            --    )
            or
                (
                    [Forecast Repeats Actual to Next Stock In]/convert(float,[Available Stock]) < 1.1
                and ([Forecast Repeats Actual to Next Stock In]/convert(float,[Available Stock])) > ([Ringfenced Quantity]/convert(float,[Forecast Repeats Actual to Next Stock In]))
                and abs(datediff(day,[Ringfenced To],[Estimated Stock In])) >= 7 
				)
            )
    then -1 
    else 
        case when 
                [Forecast Repeats Actual to Next Stock In] > 0 
            and [Available Stock] > 0 
            and [Ringfenced To] is null 
        then 
            case when 
                    [Ringfence Action Date] = convert(date,dateaddedUTC) 
                and [Forecast Repeats Actual to Next Stock In]/convert(float,[Opening Stock]) > 0.1 
            then -2 
            else 
                datediff(week,dateaddedUTC,[Ringfence Action Date])
            end 
			else 999
        end 
    end ord_ringFenceAction
	,p.[Outstanding Quantity] [Expected Stock]
from
    c
left join
	Purchase_Line p
on
	(
		c.[Purchase Order Ref.] = p.[Document No_]
	and c.[Item Code] = p.No_
	)
GO
