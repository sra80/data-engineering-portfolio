create procedure ext.sp_Customer_Status_History_Rebuild
    (
        @cus nvarchar(20)
    )

as

--deletes and re-adds a customer to ext.Customer_Status_History, as Merged_CSH_Moving_Extended_TSUTC is set to null, the customer record will in turn be removed and re-added to marketing.CSH_Moving_Extended & marketing.CSH_Moving_Extended_SKU

set nocount on

delete from ext.Customer_Status_History where No_ = @cus

--merge not necessary, a little lazy, though consistent code - copied from ext.CSH_Both
merge ext.Customer_Status_History t
using
    (
    select 
        @cus No_,
        y.event_date,
        y.customer_status,
        y.last_order
    from
        ext.fn_Customer_Status_History(@cus) y
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

--set the [End Date]
update csh set
        csh.[End Date] = ed2.ed,
        csh.UpdatedTSUTC = getutcdate() --
    from
        (
        select top 100000
            No_,
            [Start Date],
            ed
        from
            (
            select 
                No_,
                [Start Date]
                ,dateadd(day,-1,lead(h.[Start Date]) over (partition by h.No_ order by h.[Start Date])) ed
            from
                ext.Customer_Status_History h
            where
                [End Date] is null
            and No_ = @cus
            ) ed
        where
            ed.ed is not null
        ) ed2
    join
        ext.Customer_Status_History csh
    on
        (
            ed2.No_ = csh.No_
        and ed2.[Start Date] = csh.[Start Date]
        )
GO
