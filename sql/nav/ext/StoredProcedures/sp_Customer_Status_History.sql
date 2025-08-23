CREATE procedure [ext].[sp_Customer_Status_History]

as

/*
 Description:		Sets customer status using a moving date window
 Project:			112
 Creator:			Shaun Edwards(SE)
 Copyright:			CompanyX Limited, 2021
MOD	DATE	INITS	COMMENTS
00  211013  SE
01  211020  SE
02  211210  SE      Switch archive source from dbo to ext
03  211210  SE      h.[Sales Order Status] = 1 added, sp_sales no longer filtering this column
04  220106  SE      Add last order date against current status
05  220110  SE      Change to merge as last order date can change for existing lines over time
06  220111  SE      Remove separate processing for archive
07  220209  SE      Misalignment caused when order date changes, added DeletedTSUTC to flag entries when this occurs.
*/

merge ext.Customer_Status_History t
using
    (
    select 
        x.No_,
        y.event_date,
        y.customer_status,
        y.last_order
    from
        (
            select [Sell-to Customer No_] No_ from ext.Sales_Header where [Sales Order Status] = 1

            union

            select [Sell-to Customer No_] from ext.Sales_Header_Archive a left join ext.Customer_Status_History h on a.[Sell-to Customer No_] = h.No_ where h.No_ is null

            union

            select
                h.No_
            from
                (
                    select No_, max([Start Date]) [Start Date] from ext.Customer_Status_History group by No_
                ) le
            join
                ext.Customer_Status_History h
            on
                (
                    le.No_ = h.No_
                and le.[Start Date] = h.[Start Date]
                )
            where
                (
                    (
                        h.Status = 4
                    and dateadd(year,2,h.[Last Order]) < convert(date,getutcdate())
                    )
                )
        ) x
    cross apply
        ext.fn_Customer_Status_History(x.No_) y
    ) s
on
    (
        t.No_ = s.No_
    and t.[Start Date] = s.event_date
    )
when matched and t.[Last Order] < s.last_order then update set
    t.[Status] = s.customer_status, t.[Last Order] = s.last_order, t.UpdatedTSUTC = getutcdate()
when not matched by target then insert
    ([No_], [Start Date], [Status], [Last Order]) values (s.No_, s.event_date, s.customer_status, s.last_order);

--
update y set DeletedTSUTC = getutcdate() from (select No_, [Start Date], case when [Status] = lead([Status]) over (partition by No_ order by [Start Date]) then 1 else 0 end x from ext.Customer_Status_History) x join ext.Customer_Status_History y on x.No_ = y.No_ and x.[Start Date] = y.[Start Date] where x.x = 1
GO
